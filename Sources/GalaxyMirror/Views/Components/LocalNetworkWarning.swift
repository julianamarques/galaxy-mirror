import SwiftUI

struct LocalNetworkWarning: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            VStack(alignment: .leading, spacing: 4) {
                Text("O macOS está bloqueando o acesso do Galaxy Mirror à Rede Local, por isso o Galaxy não aparece.")
                    .foregroundStyle(.primary)
                Button("Abrir Ajustes de Rede Local") { openURL(Links.localNetworkSettings) }
                    .buttonStyle(.link)
            }
        }
        .font(.callout)
    }
}
