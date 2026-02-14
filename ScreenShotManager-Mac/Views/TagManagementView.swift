import SwiftUI
import ScreenShotManagerCore

/// Compact tag CRUD panel for macOS.
struct TagManagementView: View {

    @EnvironmentObject var appState: AppState
    @State private var newTagName = ""
    @State private var newTagColor = Color.blue
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Manage Tags")
                    .font(.headline)
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
            }
            .padding(12)

            Divider()

            // Tag list
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(appState.tags, id: \.id) { tag in
                        TagRow(tag: tag, onDelete: {
                            appState.deleteTag(tag)
                        })
                    }
                }
                .padding(8)
            }
            .frame(maxHeight: 200)

            Divider()

            // Add new tag
            HStack(spacing: 8) {
                ColorPicker("", selection: $newTagColor, supportsOpacity: false)
                    .labelsHidden()
                    .frame(width: 24, height: 24)

                TextField("New tag name", text: $newTagName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .onSubmit { addTag() }

                Button {
                    addTag()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
                .disabled(newTagName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(12)
        }
        .frame(width: 280)
    }

    private func addTag() {
        let name = newTagName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        appState.createTag(name: name, color: newTagColor)
        newTagName = ""
    }
}

// MARK: - Tag Row

private struct TagRow: View {

    let tag: Tag
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(hex: tag.colorHex ?? "#888888"))
                .frame(width: 10, height: 10)

            Text(tag.name ?? "Untitled")
                .font(.system(size: 12))
                .lineLimit(1)

            Spacer()

            if isHovered {
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isHovered ? Color.gray.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
