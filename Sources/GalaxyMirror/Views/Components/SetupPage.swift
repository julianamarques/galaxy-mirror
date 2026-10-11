import SwiftUI

struct SetupPage<Header: View, Content: View, Buttons: View>: View {
    let title: Text
    @ViewBuilder var header: Header
    @ViewBuilder var content: Content
    @ViewBuilder var buttons: Buttons

    var body: some View {
        VStack(spacing: 0) {
            header
                .frame(maxWidth: .infinity, minHeight: 300, maxHeight: 300)
            VStack(alignment: .leading, spacing: 10) {
                title.font(.title2.bold())
                content
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: 460, alignment: .leading)
            .frame(maxWidth: .infinity)
            Spacer(minLength: 16)
            HStack(spacing: 12) { buttons }
                .pillStyle()
        }
        .padding(28)
    }
}

extension SetupPage {
    init(
        title: LocalizedStringKey,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content,
        @ViewBuilder buttons: () -> Buttons
    ) {
        self.init(title: Text(title), header: header, content: content, buttons: buttons)
    }
}
