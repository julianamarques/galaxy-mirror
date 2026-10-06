import SwiftUI

struct RootView: View {
    @EnvironmentObject private var app: AppModel

    var body: some View {
        if app.showingSetup {
            SetupFlowView(setup: app.setup)
        } else {
            DeviceView()
        }
    }
}
