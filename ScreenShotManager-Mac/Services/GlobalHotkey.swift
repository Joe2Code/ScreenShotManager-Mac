import AppKit
import Carbon.HIToolbox

/// Global hotkey handler for Cmd+Shift+S.
final class GlobalHotkey {

    private var monitor: Any?

    /// Starts listening for Cmd+Shift+S globally.
    func register(action: @escaping () -> Void) {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            // Cmd+Shift+S
            if event.modifierFlags.contains([.command, .shift]),
               event.keyCode == UInt16(kVK_ANSI_S) {
                action()
            }
        }
    }

    /// Stops listening for the global hotkey.
    func unregister() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    deinit {
        unregister()
    }
}
