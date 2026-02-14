import SwiftUI
import ScreenShotManagerCore

/// Sidebar panel showing smart folders with match counts.
struct SmartFoldersPanel: View {

    @EnvironmentObject var appState: AppState
    @Binding var selectedFolderID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerRow
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            Divider()

            ScrollView {
                LazyVStack(spacing: 2) {
                    // "All Screenshots" row
                    folderRow(name: "All Screenshots", icon: "photo.on.rectangle.angled", count: appState.totalCount, id: nil)

                    Divider()
                        .padding(.vertical, 4)

                    // Smart folder results
                    ForEach(appState.smartFolderEngine.smartFolderResults) { result in
                        folderRow(name: result.name, icon: result.iconName, count: result.matchCount, id: result.id)
                    }

                    // Tag-based sections
                    if !appState.tags.isEmpty {
                        Divider()
                            .padding(.vertical, 4)

                        Text("Tags")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 12)

                        ForEach(appState.tags, id: \.id) { tag in
                            tagRow(tag: tag)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Components

    private var headerRow: some View {
        HStack {
            Text("Folders")
                .font(.headline)
            Spacer()
            Button {
                appState.refreshSmartFolders()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .help("Refresh smart folders")
        }
    }

    private func folderRow(name: String, icon: String, count: Int, id: UUID?) -> some View {
        Button {
            selectedFolderID = id
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .frame(width: 16)
                    .foregroundStyle(selectedFolderID == id ? .white : .secondary)

                Text(name)
                    .font(.system(size: 12))
                    .lineLimit(1)

                Spacer()

                Text("\(count)")
                    .font(.caption2)
                    .foregroundColor(selectedFolderID == id ? .white.opacity(0.8) : .gray)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(selectedFolderID == id ? Color.accentColor : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 4)
    }

    private func tagRow(tag: Tag) -> some View {
        Button {
            appState.filterByTag(tag)
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(hex: tag.colorHex ?? "#888888"))
                    .frame(width: 8, height: 8)

                Text(tag.name ?? "Untitled")
                    .font(.system(size: 12))
                    .lineLimit(1)

                Spacer()

                Text("\(tag.screenshotsArray.count)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 4)
    }
}
