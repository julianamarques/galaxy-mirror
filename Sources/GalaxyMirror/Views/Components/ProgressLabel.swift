import SwiftUI

struct ProgressLabel: View {
    let text: LocalizedStringKey

    init(_ text: LocalizedStringKey) {
        self.text = text
    }

    var body: some View {
        HStack(spacing: 8) {
            ProgressView().controlSize(.small)
            Text(text)
        }
    }
}
