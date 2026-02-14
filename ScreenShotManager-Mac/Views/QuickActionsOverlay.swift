import SwiftUI
import ScreenShotManagerCore

/// Hover overlay with quick action buttons for a screenshot thumbnail.
struct QuickActionsOverlay: View {

    let screenshot: Screenshot
    let onCopyOCR: () -> Void
    let onDelete: () -> Void
    let onOpenFinder: () -> Void
    let onTag: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            if screenshot.ocrProcessed, let text = screenshot.ocrText, !text.isEmpty {
                actionButton(icon: "doc.on.doc", help: "Copy OCR text", action: onCopyOCR)
            }

            actionButton(icon: "folder", help: "Show in Finder", action: onOpenFinder)
            actionButton(icon: "tag", help: "Add tag", action: onTag)
            actionButton(icon: "trash", help: "Delete", tint: .red, action: onDelete)
        }
        .padding(4)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func actionButton(icon: String, help: String, tint: Color = .primary, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(tint)
                .frame(width: 20, height: 20)
        }
        .buttonStyle(.plain)
        .help(help)
    }
}
