import Foundation

/// Lightweight display model for screenshots in the UI.
struct ScreenshotInfo: Identifiable {
    let id: String
    let creationDate: Date?
    let ocrText: String?
    let isOCRProcessed: Bool
    let localImagePath: String?
}
