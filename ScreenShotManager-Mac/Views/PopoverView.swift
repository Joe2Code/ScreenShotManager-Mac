import SwiftUI
import ScreenShotManagerCore

/// Main popover content shown when clicking the menu bar icon.
struct PopoverView: View {

    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            SearchBarView(query: $appState.searchQuery)
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 8)

            Divider()

            // Screenshot grid
            if appState.screenshots.isEmpty {
                emptyState
            } else {
                ThumbnailGridView(
                    screenshots: appState.screenshots,
                    imageStorage: appState.imageStorage,
                    onDelete: { appState.deleteScreenshot($0) },
                    onCopyOCR: { appState.copyOCRText(for: $0) },
                    onOpenFinder: { appState.openInFinder($0) }
                )
            }

            Divider()

            // Status bar
            statusBar
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .frame(width: 360, height: 480)
        .background(.ultraThinMaterial)
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
            Text("Screenshots from ~/Desktop will appear here")
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
