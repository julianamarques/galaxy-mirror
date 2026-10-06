import SwiftUI

struct DeviceView: View {
    @EnvironmentObject private var app: AppModel

    var body: some View {
        SetupPage(title: app.deviceName) {
            MirrorIllustration(status: illustrationStatus)
        } content: {
            VStack(alignment: .leading, spacing: 8) {
                statusLine
                if let error = app.mirrorError ?? connectionError {
                    ErrorDetail(error)
                }
            }
        } buttons: {
            SettingsPillLink()
            Spacer()
            if app.isMirroring {
                PillButton("Parar", prominent: true) { app.stopMirroring() }
            } else {
                PillButton("Espelhar", prominent: true) { Task { await app.startMirroring() } }
                    .disabled(app.connection == .connecting)
            }
        }
    }

    private var illustrationStatus: MirrorIllustration.Status {
        switch app.connection {
        case .connecting: .searching
        case .connected: .connected
        default: .idle
        }
    }

    private var connectionError: String? {
        if case .failed(let message) = app.connection { return message }
        return nil
    }

    @ViewBuilder
    private var statusLine: some View {
        if app.isMirroring {
            Label("Espelhando. Feche a janela do Galaxy para encerrar.", systemImage: "rectangle.on.rectangle")
        } else {
            switch app.connection {
            case .idle:
                Text("Clique em Espelhar para ver e controlar o Galaxy neste Mac.")
            case .connecting:
                ProgressLabel("Procurando o Galaxy na rede…")
            case .connected:
                Label("Conectado por Wi-Fi", systemImage: "wifi")
            case .failed:
                Text("Não foi possível conectar. Verifique se o Galaxy está desbloqueado, na mesma rede Wi-Fi e com a Depuração sem fio ativada.")
            }
        }
    }
}
