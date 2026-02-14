import SwiftUI

/// Menu bar icon that changes based on app state. SF Symbols only — no mascot.
struct MenuBarIcon: View {

    let state: AppState.IconState

    var body: some View {
        Image(systemName: iconName)
    }

    private var iconName: String {
        switch state {
        case .idle:
            return "viewfinder"
        case .newScreenshot:
            return "viewfinder.circle.fill"
        case .processing:
            return "viewfinder.rectangular"
        case .paused:
            return "viewfinder.trianglebadge.exclamationmark"
        }
    }
}
