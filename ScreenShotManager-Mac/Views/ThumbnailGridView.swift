import SwiftUI
import ScreenShotManagerCore
import UniformTypeIdentifiers

/// Screenshot grid with hover effects, time grouping, and drag support.
struct ThumbnailGridView: View {

    let screenshots: [Screenshot]
    let imageStorage: CoreImageStorage
    let onSelect: (Screenshot) -> Void
    let onDelete: (Screenshot) -> Void
    let onCopyOCR: (Screenshot) -> Void
    let onCopyImage: (Screenshot) -> Void
    let onOpenFinder: (Screenshot) -> Void
    let selectedID: String?
    var columnCount: Int = 1
    var hasMore: Bool = false
    var remainingCount: Int = 0
    var onLoadMore: (() -> Void)?

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: columnCount)
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(groupedScreenshots, id: \.title) { group in
                    Section {
                        ForEach(group.screenshots, id: \.localIdentifier) { screenshot in
                            ThumbnailCard(
                                screenshot: screenshot,
                                imageStorage: imageStorage,
                                isSelected: screenshot.localIdentifier == selectedID,
                                onSelect: { onSelect(screenshot) },
                                onDelete: { onDelete(screenshot) },
                                onCopyOCR: { onCopyOCR(screenshot) },
                                onCopyImage: { onCopyImage(screenshot) },
                                onOpenFinder: { onOpenFinder(screenshot) }
                            )
                        }
                    } header: {
                        HStack {
                            Text(group.title)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.top, group.title == groupedScreenshots.first?.title ? 0 : 8)
                    }
                }
            }
            .padding(16)

            if hasMore, let onLoadMore = onLoadMore {
                Button {
                    onLoadMore()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.circle")
                        Text("Load More (\(remainingCount) remaining)")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
    }

    // MARK: - Grouping

    private struct ScreenshotGroup {
        let title: String
        let screenshots: [Screenshot]
    }

    private var groupedScreenshots: [ScreenshotGroup] {
        let calendar = Calendar.current
        let now = Date()

        var today: [Screenshot] = []
        var yesterday: [Screenshot] = []
        var thisWeek: [Screenshot] = []
        var older: [Screenshot] = []

        for screenshot in screenshots {
            guard let date = screenshot.creationDate else {
                older.append(screenshot)
                continue
            }

            if calendar.isDateInToday(date) {
                today.append(screenshot)
            } else if calendar.isDateInYesterday(date) {
                yesterday.append(screenshot)
            } else if let weekAgo = calendar.date(byAdding: .day, value: -7, to: now),
                      date > weekAgo {
                thisWeek.append(screenshot)
            } else {
                older.append(screenshot)
            }
        }

        var groups: [ScreenshotGroup] = []
        if !today.isEmpty { groups.append(ScreenshotGroup(title: "Today", screenshots: today)) }
        if !yesterday.isEmpty { groups.append(ScreenshotGroup(title: "Yesterday", screenshots: yesterday)) }
        if !thisWeek.isEmpty { groups.append(ScreenshotGroup(title: "This Week", screenshots: thisWeek)) }
        if !older.isEmpty { groups.append(ScreenshotGroup(title: "Older", screenshots: older)) }

        return groups
    }
}

// MARK: - Thumbnail Card

struct ThumbnailCard: View {

    let screenshot: Screenshot
    let imageStorage: CoreImageStorage
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onCopyOCR: () -> Void
    let onCopyImage: () -> Void
    let onOpenFinder: () -> Void

    @State private var isHovered = false

    var body: some View {
        ZStack(alignment: .bottom) {
            thumbnailImage
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: isSelected ? Color.accentColor.opacity(0.5) : (isHovered ? Color.accentColor.opacity(0.3) : .clear), radius: isSelected ? 6 : 4)
                .scaleEffect(isHovered ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: isHovered)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                )

            // OCR indicator with gold tint
            if screenshot.ocrProcessed, !isHovered {
                HStack {
                    Spacer()
                    Image(systemName: "text.viewfinder")
                        .font(.system(size: 8))
                        .foregroundColor(DesignTokens.primary)
                        .padding(3)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .padding(4)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .transition(.opacity)
            }

            // Quick actions on hover
            if isHovered {
                QuickActionsOverlay(
                    screenshot: screenshot,
                    onCopyOCR: onCopyOCR,
                    onDelete: onDelete,
                    onOpenFinder: onOpenFinder,
                    onTag: {} // Tag picker handled via context menu for now
                )
                .transition(.opacity)
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .onTapGesture { onSelect() }
        .onDrag {
            guard let path = screenshot.localImagePath else {
                return NSItemProvider()
            }
            let url = imageStorage.imageURL(relativePath: path)
            return NSItemProvider(object: url as NSURL)
        }
        .contextMenu {
            Button("Copy Image") { onCopyImage() }
            if screenshot.ocrProcessed, let text = screenshot.ocrText, !text.isEmpty {
                Button("Copy OCR Text") { onCopyOCR() }
            }
            Divider()
            Button("Show in Finder") { onOpenFinder() }
            Button("Delete", role: .destructive) { onDelete() }
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
                    .fill(Color.gray.opacity(0.2))
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.tertiary)
                    }
            }
        }
    }
}
