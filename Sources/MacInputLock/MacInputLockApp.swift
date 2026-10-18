import SwiftUI

@main
struct MacInputLockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

@MainActor
private final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controls: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        controls = StatusBarController()
        Task { @MainActor in
            // Wait for AppKit to place the menu-bar item.
            try? await Task.sleep(for: .milliseconds(150))
            controls?.showOnLaunch()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        controls?.showWindow()
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        controls?.stop()
    }
}
