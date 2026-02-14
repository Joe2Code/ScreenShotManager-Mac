import Foundation
import AppKit
import ScreenShotManagerCore

/// macOS OCR orchestration using OCREngine from the shared package.
final class MacOCRService {

    private let ocrEngine = OCREngine()
    private let persistenceController: CorePersistenceController

    init(persistenceController: CorePersistenceController) {
        self.persistenceController = persistenceController
    }

    /// Processes OCR for a single NSImage and stores the result.
    func processScreenshot(_ image: NSImage, identifier: String) async {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }

        let text = await ocrEngine.recognizeText(in: cgImage)

        if !text.isEmpty {
            persistenceController.updateOCRTextInBackground(for: identifier, text: text)
            await MainActor.run {
                NotificationCenter.default.post(name: .ocrTextUpdated, object: nil)
            }
        }
    }

    /// Processes all unprocessed screenshots.
    func processUnprocessed() async {
        let unprocessed = persistenceController.fetchUnprocessedScreenshots()

        for screenshot in unprocessed {
            guard let identifier = screenshot.localIdentifier,
                  let path = screenshot.localImagePath else { continue }

            let imageURL = SharedConstants.sharedScreenshotsDirectory.appendingPathComponent(path)
            guard let image = NSImage(contentsOf: imageURL) else { continue }

            await processScreenshot(image, identifier: identifier)
        }
    }
}
