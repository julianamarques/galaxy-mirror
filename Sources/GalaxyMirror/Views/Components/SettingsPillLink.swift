import SwiftUI

struct SettingsPillLink: View {
    var body: some View {
        SettingsLink { Text("Ajustes…").frame(minWidth: PillButton.minWidth) }
            .pillButtonStyle()
    }
}
