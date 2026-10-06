import SwiftUI

struct ProminentPillStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3)
            .foregroundStyle(.white.opacity(isEnabled ? 1 : 0.6))
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.accentColor.opacity(isEnabled ? 1 : 0.35)))
            .brightness(configuration.isPressed ? -0.12 : 0)
            .contentShape(Capsule())
    }
}
