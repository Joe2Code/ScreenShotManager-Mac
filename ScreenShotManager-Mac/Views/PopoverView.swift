import SwiftUI
import AppKit
import ScreenShotManagerCore
import UniformTypeIdentifiers

/// Main popover content shown when clicking the menu bar icon.
struct PopoverView: View {

    @EnvironmentObject var appState: AppState
    @AppStorage("gridColumnCount") private var gridColumnCount = 1
    @State private var showTagManager = false
    @State private var showSidebar = false

    var body: some View {
        VStack(spacing: 0) {
            if let screenshot = appState.selectedScreenshot {
                // Detail view
                ScreenshotDetailView(
                    screenshot: screenshot,
                    imageStorage: appState.imageStorage,
                    onClose: { appState.selectedScreenshot = nil },
                    onCopyOCR: { appState.copyOCRText(for: screenshot) },
                    onOpenFinder: { appState.openInFinder(screenshot) },
                    onDelete: {
                        appState.deleteScreenshot(screenshot)
                    }
                )
            } else {
                // Main list view
                mainListView
            }
        }
        .frame(width: showSidebar ? 680 : 500, height: 650)
        .background(.ultraThinMaterial)
        .onDrop(of: [.image], isTargeted: nil) { providers in
            appState.importDroppedImage(providers)
            return true
        }
        .sheet(isPresented: $showTagManager) {
            TagManagementView()
                .environmentObject(appState)
        }
        .background(
            KeyEventHandler(
                onRightArrow: { appState.selectNext() },
                onLeftArrow: { appState.selectPrevious() },
                onReturn: {
                    if appState.selectedScreenshot == nil, let first = appState.screenshots.first {
                        appState.selectedScreenshot = first
                    }
                },
                onEscape: {
                    if appState.selectedScreenshot != nil {
                        appState.selectedScreenshot = nil
                    }
                },
                onCmdC: { appState.copySelectedOCR() }
            )
        )
    }

    // MARK: - Main List View

    private var mainListView: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbar
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 8)

            // Search bar
            SearchBarView(query: $appState.searchQuery)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)

            Divider()

            // Content area
            HStack(spacing: 0) {
                if showSidebar {
                    SmartFoldersPanel(selectedFolderID: $appState.selectedFolderID)
                        .environmentObject(appState)
                        .frame(width: 160)

                    Divider()
                }

                // Screenshot grid
                if appState.screenshots.isEmpty {
                    emptyState
                } else {
                    ThumbnailGridView(
                        screenshots: appState.visibleScreenshots,
                        imageStorage: appState.imageStorage,
                        onSelect: { appState.selectedScreenshot = $0 },
                        onDelete: { appState.deleteScreenshot($0) },
                        onCopyOCR: { appState.copyOCRText(for: $0) },
                        onCopyImage: { appState.copyImage(for: $0) },
                        onOpenFinder: { appState.openInFinder($0) },
                        selectedID: appState.selectedScreenshot?.localIdentifier,
                        columnCount: gridColumnCount,
                        hasMore: appState.hasMore,
                        remainingCount: appState.screenshots.count - appState.visibleScreenshots.count,
                        onLoadMore: { appState.loadMore() }
                    )
                }
            }

            Divider()

            // Status bar
            statusBar
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showSidebar.toggle()
                }
            } label: {
                Image(systemName: "sidebar.left")
                    .foregroundColor(showSidebar ? .accentColor : .secondary)
            }
            .buttonStyle(.plain)
            .help("Toggle sidebar")

            if appState.selectedTagFilter != nil || appState.selectedFolderID != nil {
                Button {
                    appState.clearFilters()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                        Text("Clear filter")
                    }
                    .font(.caption)
                    .foregroundStyle(.orange)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Button {
                showTagManager = true
            } label: {
                Image(systemName: "tag")
            }
            .buttonStyle(.plain)
            .help("Manage tags")
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No Screenshots")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Screenshots from ~/Desktop will appear here.\nDrag & drop images to import.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack {
            Text("\(appState.totalCount) screenshots")
                .font(.caption)
                .foregroundStyle(.secondary)

            if appState.isProcessingOCR {
                ProgressView()
                    .scaleEffect(0.6)
                Text("OCR...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                appState.togglePause()
            } label: {
                Image(systemName: appState.isPaused ? "play.circle" : "pause.circle")
                    .foregroundStyle(appState.isPaused ? .orange : .secondary)
            }
            .buttonStyle(.plain)
            .help(appState.isPaused ? "Resume watching" : "Pause watching")
        }
    }
}

// MARK: - Key Event Handler (macOS 13 compatible)

private struct KeyEventHandler: NSViewRepresentable {
    let onRightArrow: () -> Void
    let onLeftArrow: () -> Void
    let onReturn: () -> Void
    let onEscape: () -> Void
    let onCmdC: () -> Void

    func makeNSView(context: Context) -> KeyCaptureView {
        let view = KeyCaptureView()
        view.onRightArrow = onRightArrow
        view.onLeftArrow = onLeftArrow
        view.onReturn = onReturn
        view.onEscape = onEscape
        view.onCmdC = onCmdC
        return view
    }

    func updateNSView(_ nsView: KeyCaptureView, context: Context) {
        nsView.onRightArrow = onRightArrow
        nsView.onLeftArrow = onLeftArrow
        nsView.onReturn = onReturn
        nsView.onEscape = onEscape
        nsView.onCmdC = onCmdC
    }
}

private final class KeyCaptureView: NSView {
    var onRightArrow: (() -> Void)?
    var onLeftArrow: (() -> Void)?
    var onReturn: (() -> Void)?
    var onEscape: (() -> Void)?
    var onCmdC: (() -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 124: // Right arrow
            onRightArrow?()
        case 123: // Left arrow
            onLeftArrow?()
        case 36: // Return
            onReturn?()
        case 53: // Escape
            onEscape?()
        case 8 where event.modifierFlags.contains(.command): // Cmd+C
            onCmdC?()
        default:
            super.keyDown(with: event)
        }
    }
}
