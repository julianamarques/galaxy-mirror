import SwiftUI

struct ErrorDetail: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.tertiary)
            .lineLimit(4)
            .textSelection(.enabled)
    }
}
