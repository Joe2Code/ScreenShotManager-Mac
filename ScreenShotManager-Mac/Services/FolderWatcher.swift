import Foundation
import Combine

/// Watches a directory for new screenshot files using FSEvents.
final class FolderWatcher: ObservableObject {

    @Published var detectedFiles: [URL] = []

    private var stream: FSEventStreamRef?
    private var knownFiles: Set<String> = []
    private let watchedURL: URL

    /// Screenshot naming pattern: "Screenshot *.png" or "Screen Shot *.png"
    private let screenshotPattern = try! NSRegularExpression(
        pattern: "^(Screenshot|Screen Shot|CleanShot).*\\.(png|jpg|jpeg|tiff)$",
        options: .caseInsensitive
    )

    init(watchPath: URL? = nil) {
        self.watchedURL = watchPath ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
        scanExistingFiles()
        start()
    }

    deinit {
        stop()
    }

    // MARK: - Scanning

    private func scanExistingFiles() {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: watchedURL,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        for url in contents where isScreenshot(url) {
            knownFiles.insert(url.lastPathComponent)
        }
    }

    /// Returns URLs of all existing screenshot files in the watched directory.
    func existingScreenshotURLs() -> [URL] {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: watchedURL,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        return contents
            .filter { isScreenshot($0) }
            .sorted { a, b in
                let dateA = (try? a.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? .distantPast
                let dateB = (try? b.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? .distantPast
                return dateA > dateB
            }
    }

    private func isScreenshot(_ url: URL) -> Bool {
        let name = url.lastPathComponent
        let range = NSRange(name.startIndex..<name.endIndex, in: name)
        return screenshotPattern.firstMatch(in: name, range: range) != nil
    }

    // MARK: - FSEvents

    func start() {
        guard stream == nil else { return }

        let path = watchedURL.path as CFString
        let pathsToWatch = [path] as CFArray

        var context = FSEventStreamContext()
        context.info = Unmanaged.passUnretained(self).toOpaque()

        let callback: FSEventStreamCallback = { _, clientCallBackInfo, numEvents, eventPaths, _, _ in
            guard let info = clientCallBackInfo else { return }
            let watcher = Unmanaged<FolderWatcher>.fromOpaque(info).takeUnretainedValue()

            let paths = Unmanaged<CFArray>.fromOpaque(eventPaths).takeUnretainedValue() as! [String]

            DispatchQueue.main.async {
                watcher.handleEvents(paths: paths)
            }
        }

        stream = FSEventStreamCreate(
            nil,
            callback,
            &context,
            pathsToWatch,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            1.0, // 1-second latency
            UInt32(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes)
        )

        if let stream = stream {
            FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
            FSEventStreamStart(stream)
        }
    }

    func stop() {
        guard let stream = stream else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        self.stream = nil
    }

    private func handleEvents(paths: [String]) {
        var newFiles: [URL] = []

        // Re-scan directory for new screenshot files
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: watchedURL,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        for url in contents where isScreenshot(url) {
            let name = url.lastPathComponent
            if !knownFiles.contains(name) {
                knownFiles.insert(name)
                newFiles.append(url)
            }
        }

        if !newFiles.isEmpty {
            detectedFiles.append(contentsOf: newFiles)
        }
    }

    func clearDetected() {
        detectedFiles.removeAll()
    }
}
