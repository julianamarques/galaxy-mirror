import SwiftUI

struct PillButton: View {
    static let minWidth: CGFloat = 110

    let title: String
    let prominent: Bool
    let action: () -> Void

    init(_ title: String, prominent: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.prominent = prominent
        self.action = action
    }

    var body: some View {
        Button(action: action) { Text(title).frame(minWidth: Self.minWidth) }
            .keyboardShortcut(prominent ? KeyboardShortcut(.return, modifiers: []) : nil)
            .pillButtonStyle(prominent: prominent)
    }
}
