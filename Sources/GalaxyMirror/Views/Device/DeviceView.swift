import SwiftUI

struct DeviceView: View {
    @EnvironmentObject private var app: AppModel
    @Environment(\.openURL) private var openURL

    var body: some View {
        SetupPage(title: Text(app.deviceName)) {
            MirrorIllustration(status: illustrationStatus)
        } content: {
            VStack(alignment: .leading, spacing: 8) {
                statusLine
                if let detail = app.mirrorError ?? problem?.detail {
                    ErrorDetail(detail)
                }
            }
        } buttons: {
            SettingsPillLink()
            Spacer()
            if app.isMirroring {
                PillButton("Parar", prominent: true) { app.stopMirroring() }
            } else {
                if app.pairedDevice?.supportsWiFi == false {
                    PillButton("Configurar Wi-Fi") { app.setUpWiFi() }
                }
                PillButton("Espelhar", prominent: true) { app.startMirroring() }
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

    private var problem: ConnectionProblem? {
        if case .failed(let problem) = app.connection { return problem }
        return nil
    }

    @ViewBuilder
    private var statusLine: some View {
        if app.mirrorState == .starting {
            ProgressLabel("Iniciando o espelhamento…")
        } else if app.mirrorState == .reconnecting {
            ProgressLabel("Reconectando ao Galaxy…")
        } else if app.mirrorState == .running {
            Label("Espelhando. Feche a janela do Galaxy para encerrar.", systemImage: "rectangle.on.rectangle")
        } else {
            switch app.connection {
            case .idle:
                Text("Clique em Espelhar para ver e controlar o Galaxy neste Mac.")
            case .connecting:
                ProgressLabel("Procurando o Galaxy…")
            case .connected(let serial):
                if ADBOutputParser.isUSBSerial(serial) {
                    Label("Conectado por cabo USB", systemImage: "cable.connector")
                } else {
                    Label("Conectado por Wi-Fi", systemImage: "wifi")
                }
            case .failed(let problem):
                VStack(alignment: .leading, spacing: 4) {
                    Text(problem.title).foregroundStyle(.primary)
                    Text(problem.message)
                    if problem.needsLocalNetworkPermission {
                        Button("Abrir Ajustes de Rede Local") { openURL(Links.localNetworkSettings) }
                            .buttonStyle(.link)
                    }
                }
            }
        }
    }
}
