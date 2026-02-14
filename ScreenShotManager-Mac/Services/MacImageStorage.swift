import AppKit
import ScreenShotManagerCore

/// macOS-specific image storage helper.
/// Wraps CoreImageStorage for NSImage import convenience.
final class MacImageStorage {

    let core: CoreImageStorage

    init(core: CoreImageStorage) {
        self.core = core
    }

    /// Import an NSImage from a file URL, saving both full-size and thumbnail.
    func importImage(from url: URL, identifier: String) -> Bool {
        guard let image = NSImage(contentsOf: url) else { return false }

        guard core.saveImage(image, for: identifier) != nil else { return false }
        _ = core.saveThumbnail(image, for: identifier)

        return true
    }

    /// Load an NSImage from storage.
    func loadImage(relativePath: String) -> NSImage? {
        core.loadImage(relativePath: relativePath)
    }

    /// Load a thumbnail for an identifier.
    func loadThumbnail(for identifier: String) -> NSImage? {
        core.loadThumbnail(for: identifier)
    }
}
