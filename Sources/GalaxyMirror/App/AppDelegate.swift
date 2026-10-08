import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let app = AppModel()
    let updates = UpdateModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
        app.launched()
        updates.isBusy = { [app] in app.isMirroring }
        updates.startAutomaticChecks()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    func applicationWillTerminate(_ notification: Notification) {
        app.stopMirroring()
        app.stopMonitoring()
    }
}
