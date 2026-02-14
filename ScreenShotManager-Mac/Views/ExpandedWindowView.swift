import SwiftUI
import ScreenShotManagerCore

/// Full NSWindow with two-panel layout: sidebar + masonry grid + timeline.
struct ExpandedWindowView: View {

    @EnvironmentObject var appState: AppState
    @State private var selectedFolderID: UUID?

    private let columns = [
        GridItem(.adaptive(minimum: 120, maximum: 180), spacing: 12)
    ]

    var body: some View {
        NavigationSplitView {
            // Sidebar
            SmartFoldersPanel(selectedFolderID: $selectedFolderID)
                .environmentObject(appState)
                .frame(minWidth: 180)
        } detail: {
            // Main content
            VStack(spacing: 0) {
                // Search + toolbar
                HStack(spacing: 12) {
                    SearchBarView(query: $appState.searchQuery)
                        .frame(maxWidth: 300)

                    Spacer()

                    Text("\(appState.totalCount) screenshots")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(appState.storageUsed)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)

                Divider()

                // Screenshot grid (larger tiles)
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(appState.screenshots, id: \.localIdentifier) { screenshot in
                            ExpandedThumbnailCard(
                                screenshot: screenshot,
                                imageStorage: appState.imageStorage,
                                onSelect: { appState.selectedScreenshot = screenshot },
                                onDelete: { appState.deleteScreenshot(screenshot) },
                                onCopyOCR: { appState.copyOCRText(for: screenshot) }
                            )
                        }
                    }
                    .padding(16)
                }
            }
        }
        .frame(minWidth: 700, minHeight: 500)
        .onChange(of: selectedFolderID) { newValue in
            appState.selectedFolderID = newValue
            appState.loadScreenshots()
        }
    }
}

// MARK: - Expanded Thumbnail Card

private struct ExpandedThumbnailCard: View {

    let screenshot: Screenshot
    let imageStorage: CoreImageStorage
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onCopyOCR: () -> Void

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            thumbnailSection
            metadataSection
            tagsSection
        }
        .padding(8)
        .background(isHovered ? Color.gray.opacity(0.08) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .onTapGesture { onSelect() }
        .contextMenu {
            if screenshot.ocrProcessed, let text = screenshot.ocrText, !text.isEmpty {
                Button("Copy OCR Text") { onCopyOCR() }
            }
            Divider()
            Button("Delete", role: .destructive) { onDelete() }
        }
    }

    private var thumbnailSection: some View {
        thumbnailImage
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: isHovered ? DesignTokens.primary.opacity(0.3) : .clear, radius: 6)
            .scaleEffect(isHovered ? 1.01 : 1.0)
    }

    @ViewBuilder
    private var metadataSection: some View {
        if let date = screenshot.creationDate {
            Text(date, style: .date)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        if let text = screenshot.ocrText, !text.isEmpty {
            Text(String(text.prefix(50)))
                .font(.system(size: 10))
                .foregroundColor(DesignTokens.ocrHighlight)
                .lineLimit(2)
        }
    }

    @ViewBuilder
    private var tagsSection: some View {
        if !screenshot.tagsArray.isEmpty {
            HStack(spacing: 4) {
                ForEach(screenshot.tagsArray.prefix(3), id: \.id) { tag in
                    let bgColor = Color(hex: tag.colorHex ?? "#888888").opacity(0.2)
                    Text(tag.name ?? "")
                        .font(.system(size: 9))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(bgColor)
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var thumbnailImage: some View {
        Group {
            if let identifier = screenshot.localIdentifier,
               let nsImage = imageStorage.loadThumbnail(for: identifier) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.tertiary)
                    }
            }
        }
        .clipped()
    }
}
