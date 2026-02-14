import AppKit
import Combine

/// Monitors the system clipboard for image changes and triggers auto-import.
final class ClipboardMonitor: ObservableObject {

    @Published var detectedImage: NSImage?

    private var timer: Timer?
    private var lastChangeCount: Int

    init() {
        lastChangeCount = NSPasteboard.general.changeCount
    }

    func start() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func checkClipboard() {
        let currentCount = NSPasteboard.general.changeCount
        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        // Check if clipboard contains an image
        guard let types = NSPasteboard.general.types,
              types.contains(.tiff) || types.contains(.png) else { return }

        if let data = NSPasteboard.general.data(forType: .tiff),
           let image = NSImage(data: data) {
            DispatchQueue.main.async { [weak self] in
                self?.detectedImage = image
            }
        }
    }

    func clearDetected() {
        detectedImage = nil
    }

    deinit {
        stop()
    }
}
