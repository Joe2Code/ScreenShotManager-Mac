import SwiftUI
import ScreenShotManagerCore

@main
struct ScreenShotManagerMacApp: App {

    @StateObject private var appState = AppState()
    @State private var showSettings = false
    @State private var showStats = false

    var body: some Scene {
        // Menu bar popover
        MenuBarExtra {
            PopoverView()
                .environmentObject(appState)
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                        .environmentObject(appState)
                }
                .sheet(isPresented: $showStats) {
                    StatsView()
                        .environmentObject(appState)
                }
        } label: {
            MenuBarIcon(state: appState.iconState)
        }
        .menuBarExtraStyle(.window)

        // Right-click menu extras
        MenuBarExtra {
            rightClickMenu
        } label: {
            EmptyView()
        }

        // Expanded window
        Window("ScreenShot Manager", id: "expanded") {
            ExpandedWindowView()
                .environmentObject(appState)
        }
        .defaultSize(width: 900, height: 600)
    }

    // MARK: - Right-Click Menu

    @ViewBuilder
    private var rightClickMenu: some View {
        // Recent screenshots
        if !appState.screenshots.isEmpty {
            Menu("Recent Screenshots") {
                ForEach(appState.screenshots.prefix(5), id: \.localIdentifier) { screenshot in
                    Button {
                        appState.selectedScreenshot = screenshot
                    } label: {
                        let name = screenshot.localIdentifier ?? "Screenshot"
                        let date = screenshot.creationDate.map { DateFormatter.localizedString(from: $0, dateStyle: .short, timeStyle: .short) } ?? ""
                        Text("\(name.prefix(20)) — \(date)")
                    }
                }
            }
        }

        // Quick OCR copy
        Button("Copy Last OCR Text") {
            appState.copyLastOCRText()
        }
        .disabled(appState.screenshots.first(where: { $0.ocrProcessed && $0.ocrText?.isEmpty == false }) == nil)

        Divider()

        // Smart folders
        if !appState.smartFolderEngine.smartFolderResults.isEmpty {
            Menu("Smart Folders") {
                ForEach(appState.smartFolderEngine.smartFolderResults) { result in
                    Button("\(result.name) (\(result.matchCount))") {
                        appState.selectedFolderID = result.id
                        appState.loadScreenshots()
                    }
                }
            }
        }

        Divider()

        // Pause/Resume
        Button(appState.isPaused ? "Resume Watching" : "Pause Watching") {
            appState.togglePause()
        }

        // Stats
        Button("Statistics...") {
            showStats = true
        }

        // Settings
        Button("Settings...") {
            showSettings = true
        }

        Divider()

        // Open expanded window
        Button("Open Full Window") {
            NSApp.activate(ignoringOtherApps: true)
        }

        Button("Quit") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
