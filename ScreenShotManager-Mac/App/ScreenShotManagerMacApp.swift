import SwiftUI
import ScreenShotManagerCore

@main
struct ScreenShotManagerMacApp: App {

    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            PopoverView()
                .environmentObject(appState)
        } label: {
            MenuBarIcon(state: appState.iconState)
        }
        .menuBarExtraStyle(.window)
    }
}
