import SwiftUI
import ScreenShotManagerCore

/// Statistics panel showing screenshot counts and storage usage.
struct StatsView: View {

    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 12) {
            Text("Statistics")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 16) {
                statCard(
                    icon: "photo.stack",
                    value: "\(appState.totalCount)",
                    label: "Total"
                )
                statCard(
                    icon: "text.viewfinder",
                    value: "\(appState.ocrProcessedCount)",
                    label: "OCR Done"
                )
                statCard(
                    icon: "externaldrive",
                    value: appState.storageUsed,
                    label: "Storage"
                )
            }

            // Smart folder breakdown
            if !appState.smartFolderEngine.smartFolderResults.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Smart Folders")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    ForEach(appState.smartFolderEngine.smartFolderResults) { result in
                        HStack {
                            Image(systemName: result.iconName)
                                .frame(width: 16)
                                .foregroundStyle(.secondary)
                            Text(result.name)
                                .font(.caption)
                            Spacer()
                            Text("\(result.matchCount)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(width: 280)
    }

    private func statCard(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(DesignTokens.primary)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
