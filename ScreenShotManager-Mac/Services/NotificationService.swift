import Foundation
import UserNotifications

/// Manages local notifications for new screenshot detection and OCR completion.
final class NotificationService {

    static let shared = NotificationService()

    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func notifyNewScreenshot(filename: String) {
        let content = UNMutableNotificationContent()
        content.title = "New Screenshot"
        content.body = "Captured: \(filename)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "new-screenshot-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    func notifyOCRComplete(screenshotName: String, textPreview: String) {
        let content = UNMutableNotificationContent()
        content.title = "OCR Complete"
        let preview = textPreview.prefix(80)
        content.body = "\(screenshotName): \(preview)..."
        content.sound = nil

        let request = UNNotificationRequest(
            identifier: "ocr-complete-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
