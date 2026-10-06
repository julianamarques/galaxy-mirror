import SwiftUI

extension View {
    func pillStyle() -> some View {
        controlSize(.extraLarge).buttonBorderShape(.capsule)
    }

    @ViewBuilder
    func pillButtonStyle(prominent: Bool = false) -> some View {
        if prominent {
            buttonStyle(ProminentPillStyle())
        } else if #available(macOS 26, *) {
            buttonStyle(.glass)
        } else {
            buttonStyle(.bordered)
        }
    }
}
