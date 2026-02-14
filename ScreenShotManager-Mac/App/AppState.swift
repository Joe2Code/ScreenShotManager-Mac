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
    @Published var searchQuery: String = ""
    @Published var isPaused: Bool = false
    @Published var isProcessingOCR: Bool = false

    // MARK: - Properties

    let persistence: CorePersistenceController
    let smartFolderEngine: SmartFolderEngine
    let folderWatcher: FolderWatcher
    let ocrService: MacOCRService
    let imageStorage: CoreImageStorage

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
        if query.isEmpty {
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

        // Reset icon after a delay
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        iconState = isPaused ? .paused : .idle
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

    // MARK: - Stats

    var totalCount: Int { screenshots.count }
    var ocrProcessedCount: Int { screenshots.filter { $0.ocrProcessed }.count }
    var storageUsed: String { imageStorage.formattedStorageUsed() }
}
