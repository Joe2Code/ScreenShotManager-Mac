import SwiftUI
import ScreenShotManagerCore

/// Full-size screenshot view with OCR text display.
struct ScreenshotDetailView: View {

    let screenshot: Screenshot
    let imageStorage: CoreImageStorage
    let onClose: () -> Void
    let onCopyOCR: () -> Void
    let onOpenFinder: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Button { onClose() } label: {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .buttonStyle(.plain)

                Spacer()

                if let date = screenshot.creationDate {
                    Text(date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 12) {
                    if screenshot.ocrProcessed, screenshot.ocrText?.isEmpty == false {
                        Button { onCopyOCR() } label: {
                            Image(systemName: "doc.on.doc")
                        }
                        .buttonStyle(.plain)
                        .help("Copy OCR text")
                    }

                    Button { onOpenFinder() } label: {
                        Image(systemName: "folder")
                    }
                    .buttonStyle(.plain)
                    .help("Show in Finder")

                    Button { onDelete() } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                    .help("Delete")
                }
            }
            .padding(12)

            Divider()

            // Image
            GeometryReader { geometry in
                if let identifier = screenshot.localIdentifier,
                   let path = screenshot.localImagePath,
                   let nsImage = imageStorage.loadImage(relativePath: path) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onDrag {
                            let url = imageStorage.imageURL(relativePath: path)
                            return NSItemProvider(object: url as NSURL)
                        }
                } else {
                    placeholderImage
                }
            }

            // OCR Text
            if let ocrText = screenshot.ocrText, !ocrText.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "text.viewfinder")
                            .font(.caption)
                        Text("OCR Text")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Spacer()
                        Button("Copy") { onCopyOCR() }
                            .font(.caption)
                            .buttonStyle(.plain)
                            .foregroundColor(.accentColor)
                    }

                    ScrollView {
                        Text(ocrText)
                            .font(.system(size: 11, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 100)
                }
                .padding(12)
            }

            // Tags
            if !screenshot.tagsArray.isEmpty {
                Divider()

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(screenshot.tagsArray, id: \.id) { tag in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color(hex: tag.colorHex ?? "#888888") ?? .gray)
                                    .frame(width: 6, height: 6)
                                Text(tag.name ?? "")
                                    .font(.caption2)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.gray.opacity(0.15))
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }
        }
    }

    private var placeholderImage: some View {
        VStack {
            Image(systemName: "photo")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text("Image not found")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
