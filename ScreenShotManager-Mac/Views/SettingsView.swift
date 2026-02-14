import SwiftUI
import ServiceManagement

/// Settings panel for watched folder, launch at login, and preferences.
struct SettingsView: View {

    @EnvironmentObject var appState: AppState
    @AppStorage("watchedFolderPath") private var watchedFolderPath = "~/Desktop"
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("clipboardMonitorEnabled") private var clipboardMonitorEnabled = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("gridColumnCount") private var gridColumnCount = 1
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.headline)
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
            }
            .padding(12)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Watched Folder
                    settingSection(title: "Watched Folder", icon: "folder.badge.gearshape") {
                        HStack {
                            Text(watchedFolderPath)
                                .font(.system(size: 11, design: .monospaced))
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Button("Choose...") {
                                chooseFolder()
                            }
                            .controlSize(.small)
                        }
                    }

                    // Grid Layout
                    settingSection(title: "Grid Layout", icon: "square.grid.2x2") {
                        HStack {
                            Text("Columns per row")
                                .font(.caption)
                            Spacer()
                            Picker("", selection: $gridColumnCount) {
                                Text("1").tag(1)
                                Text("2").tag(2)
                                Text("3").tag(3)
                                Text("4").tag(4)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 160)
                        }
                    }

                    // Launch at Login
                    settingSection(title: "Startup", icon: "power") {
                        Toggle("Launch at login", isOn: $launchAtLogin)
                            .toggleStyle(.switch)
                            .controlSize(.small)
                            .onChange(of: launchAtLogin) { newValue in
                                setLaunchAtLogin(newValue)
                            }
                    }

                    // Clipboard Monitor
                    settingSection(title: "Clipboard", icon: "doc.on.clipboard") {
                        Toggle("Auto-import clipboard images", isOn: $clipboardMonitorEnabled)
                            .toggleStyle(.switch)
                            .controlSize(.small)
                            .onChange(of: clipboardMonitorEnabled) { newValue in
                                if newValue {
                                    appState.clipboardMonitor.start()
                                } else {
                                    appState.clipboardMonitor.stop()
                                }
                            }
                    }

                    // Notifications
                    settingSection(title: "Notifications", icon: "bell") {
                        Toggle("Show notifications for new screenshots", isOn: $notificationsEnabled)
                            .toggleStyle(.switch)
                            .controlSize(.small)
                    }

                    // Global Hotkey
                    settingSection(title: "Hotkey", icon: "keyboard") {
                        HStack {
                            Text("Toggle popover")
                                .font(.caption)
                            Spacer()
                            Text("Cmd + Shift + S")
                                .font(.system(size: 11, design: .monospaced))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.gray.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }
                .padding(12)
            }
        }
        .frame(width: 320)
    }

    private func settingSection(title: String, icon: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(DesignTokens.primary)
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            content()
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            watchedFolderPath = url.path
            appState.folderWatcher.stop()
            // Re-create watcher with new path would require app restart or reinit
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to set launch at login: \(error)")
        }
    }
}
