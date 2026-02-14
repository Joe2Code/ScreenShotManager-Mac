import SwiftUI
import Combine
import ScreenShotManagerCore
import CoreData

/// Central state manager for the macOS menu bar app.
@MainActor
final class AppState: ObservableObject {

    // MARK: - Types

    enum IconState {
        case idle
        case newScreenshot
        case processing
        case paused
    }

    // MARK: - Published Properties

    @Published var iconState: IconState = .idle
    @Published var screenshots: [Screenshot] = []
    @Published var tags: [Tag] = []
    @Published var searchQuery: String = ""
    @Published var isPaused: Bool = false
    @Published var isProcessingOCR: Bool = false
    @Published var selectedScreenshot: Screenshot?
    @Published var selectedFolderID: UUID?
    @Published var selectedTagFilter: Tag?

    // MARK: - Properties

    let persistence: CorePersistenceController
    let smartFolderEngine: SmartFolderEngine
    let folderWatcher: FolderWatcher
    let ocrService: MacOCRService
    let imageStorage: CoreImageStorage
    let globalHotkey = GlobalHotkey()

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        let persistence = CorePersistenceController(storeURL: SharedConstants.sharedStoreURL)
        self.persistence = persistence
        self.smartFolderEngine = SmartFolderEngine(persistenceController: persistence)
        self.ocrService = MacOCRService(persistenceController: persistence)
        self.imageStorage = CoreImageStorage(
            screenshotsDirectory: SharedConstants.sharedScreenshotsDirectory,
            thumbnailsDirectory: SharedConstants.sharedThumbnailsDirectory
        )
        self.folderWatcher = FolderWatcher()

        persistence.setupDefaultSmartFoldersIfNeeded()

        setupBindings()
        loadScreenshots()
        loadTags()
        refreshSmartFolders()
    }

    // MARK: - Setup

    private func setupBindings() {
        // Watch for new screenshots from folder watcher
        folderWatcher.$detectedFiles
            .removeDuplicates()
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] files in
                guard let self = self, !files.isEmpty else { return }
                Task { await self.importNewScreenshots(files) }
            }
            .store(in: &cancellables)

        // Watch for OCR updates
        NotificationCenter.default.publisher(for: .ocrTextUpdated)
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadScreenshots()
                self?.refreshSmartFolders()
            }
            .store(in: &cancellables)

        // Search filtering
        $searchQuery
            .debounce(for: .seconds(0.3), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                self?.loadScreenshots(searchQuery: query)
            }
            .store(in: &cancellables)
    }

    // MARK: - Screenshot Loading

    func loadScreenshots(searchQuery: String? = nil) {
        let query = searchQuery ?? self.searchQuery

        if let tagFilter = selectedTagFilter {
            screenshots = persistence.fetchScreenshots(withTag: tagFilter)
            if !query.isEmpty {
                screenshots = screenshots.filter {
                    $0.ocrText?.localizedCaseInsensitiveContains(query) == true
                }
            }
        } else if let folderID = selectedFolderID {
            // Filter by smart folder
            let results = smartFolderEngine.smartFolderResults
            if let folder = results.first(where: { $0.id == folderID }) {
                let identifiers = Set(folder.matchingIdentifiers)
                let all = query.isEmpty ? persistence.fetchAllScreenshots() : persistence.searchScreenshots(query: query)
                screenshots = all.filter { identifiers.contains($0.localIdentifier ?? "") }
            } else {
                screenshots = []
            }
        } else if query.isEmpty {
            screenshots = persistence.fetchAllScreenshots()
        } else {
            screenshots = persistence.searchScreenshots(query: query)
        }
    }

    // MARK: - Import

    private func importNewScreenshots(_ fileURLs: [URL]) async {
        iconState = .newScreenshot

        for fileURL in fileURLs {
            guard let nsImage = NSImage(contentsOf: fileURL) else { continue }

            let identifier = "mac-\(UUID().uuidString)"

            // Save image to storage
            if let _ = imageStorage.saveImage(nsImage, for: identifier) {
                // Save thumbnail
                _ = imageStorage.saveThumbnail(nsImage, for: identifier)

                // Create CoreData entry
                let screenshot = persistence.fetchOrCreateScreenshot(
                    localIdentifier: identifier,
                    creationDate: Date()
                )
                screenshot.localImagePath = imageStorage.sanitizedFilename(from: identifier) + ".jpg"
                persistence.save()

                // Run OCR
                iconState = .processing
                isProcessingOCR = true
                await ocrService.processScreenshot(nsImage, identifier: identifier)
                isProcessingOCR = false
            }
        }

        // Clear detected files after import
        folderWatcher.clearDetected()
        loadScreenshots()
        refreshSmartFolders()

        // Reset icon after a delay
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        iconState = isPaused ? .paused : .idle
    }

    /// Import an image dropped onto the menu bar icon or grid.
    func importDroppedImage(_ providers: [NSItemProvider]) {
        for provider in providers {
            if provider.canLoadObject(ofClass: NSImage.self) {
                provider.loadObject(ofClass: NSImage.self) { [weak self] image, _ in
                    guard let nsImage = image as? NSImage else { return }
                    Task { @MainActor [weak self] in
                        guard let self = self else { return }
                        await self.importNewScreenshots([])
                        // Direct import from NSImage
                        let identifier = "mac-\(UUID().uuidString)"
                        if let _ = self.imageStorage.saveImage(nsImage, for: identifier) {
                            _ = self.imageStorage.saveThumbnail(nsImage, for: identifier)
                            let screenshot = self.persistence.fetchOrCreateScreenshot(
                                localIdentifier: identifier,
                                creationDate: Date()
                            )
                            screenshot.localImagePath = self.imageStorage.sanitizedFilename(from: identifier) + ".jpg"
                            self.persistence.save()
                            self.isProcessingOCR = true
                            await self.ocrService.processScreenshot(nsImage, identifier: identifier)
                            self.isProcessingOCR = false
                            self.loadScreenshots()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Actions

    func togglePause() {
        isPaused.toggle()
        iconState = isPaused ? .paused : .idle
        if isPaused {
            folderWatcher.stop()
        } else {
            folderWatcher.start()
        }
    }

    func deleteScreenshot(_ screenshot: Screenshot) {
        if let path = screenshot.localImagePath {
            imageStorage.deleteImage(relativePath: path)
        }
        if selectedScreenshot?.localIdentifier == screenshot.localIdentifier {
            selectedScreenshot = nil
        }
        persistence.deleteScreenshot(screenshot)
        loadScreenshots()
    }

    func copyOCRText(for screenshot: Screenshot) {
        guard let text = screenshot.ocrText, !text.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    func openInFinder(_ screenshot: Screenshot) {
        guard let path = screenshot.localImagePath else { return }
        let url = imageStorage.imageURL(relativePath: path)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    // MARK: - Tag Operations

    func loadTags() {
        tags = persistence.fetchAllTags()
    }

    func createTag(name: String, color: Color) {
        let hex = color.toHex() ?? "#0000FF"
        persistence.createTag(name: name, colorHex: hex)
        loadTags()
    }

    func deleteTag(_ tag: Tag) {
        persistence.deleteTag(tag)
        if selectedTagFilter?.id == tag.id {
            selectedTagFilter = nil
        }
        loadTags()
    }

    func addTag(_ tag: Tag, to screenshot: Screenshot) {
        screenshot.addToTags(tag)
        persistence.save()
        loadScreenshots()
    }

    func removeTag(_ tag: Tag, from screenshot: Screenshot) {
        screenshot.removeFromTags(tag)
        persistence.save()
        loadScreenshots()
    }

    // MARK: - Smart Folder Operations

    func refreshSmartFolders() {
        smartFolderEngine.refreshSmartFolders()
    }

    func filterByTag(_ tag: Tag) {
        selectedTagFilter = tag
        selectedFolderID = nil
        loadScreenshots()
    }

    func clearFilters() {
        selectedTagFilter = nil
        selectedFolderID = nil
        loadScreenshots()
    }

    // MARK: - Keyboard Navigation

    func selectNext() {
        guard !screenshots.isEmpty else { return }
        if let current = selectedScreenshot,
           let index = screenshots.firstIndex(where: { $0.localIdentifier == current.localIdentifier }),
           index + 1 < screenshots.count {
            selectedScreenshot = screenshots[index + 1]
        } else {
            selectedScreenshot = screenshots.first
        }
    }

    func selectPrevious() {
        guard !screenshots.isEmpty else { return }
        if let current = selectedScreenshot,
           let index = screenshots.firstIndex(where: { $0.localIdentifier == current.localIdentifier }),
           index > 0 {
            selectedScreenshot = screenshots[index - 1]
        } else {
            selectedScreenshot = screenshots.last
        }
    }

    func copySelectedOCR() {
        guard let screenshot = selectedScreenshot else { return }
        copyOCRText(for: screenshot)
    }

    // MARK: - Stats

    var totalCount: Int { screenshots.count }
    var ocrProcessedCount: Int { screenshots.filter { $0.ocrProcessed }.count }
    var storageUsed: String { imageStorage.formattedStorageUsed() }
}
