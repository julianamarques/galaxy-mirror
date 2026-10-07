import SwiftUI

@main
struct GalaxyMirrorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        Window("Galaxy Mirror", id: "main") {
            RootView()
                .environmentObject(delegate.app)
                .frame(width: 680, height: 580)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)

        Settings {
            SettingsView().environmentObject(delegate.app)
        }
    }
}
