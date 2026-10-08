import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var app: AppModel
    @EnvironmentObject private var updates: UpdateModel

    @AppStorage(SettingsKey.quality) private var quality = SettingsKey.Default.quality
    @AppStorage(SettingsKey.codec) private var codec = SettingsKey.Default.codec
    @AppStorage(SettingsKey.turnScreenOff) private var turnScreenOff = SettingsKey.Default.turnScreenOff
    @AppStorage(SettingsKey.audio) private var audio = SettingsKey.Default.audio
    @AppStorage(SettingsKey.stayAwake) private var stayAwake = SettingsKey.Default.stayAwake
    @AppStorage(SettingsKey.alwaysOnTop) private var alwaysOnTop = SettingsKey.Default.alwaysOnTop
    @AppStorage(SettingsKey.lockOnClose) private var lockOnClose = SettingsKey.Default.lockOnClose
    @AppStorage(SettingsKey.autoStart) private var autoStart = SettingsKey.Default.autoStart
    @AppStorage(SettingsKey.virtualDisplay) private var virtualDisplay = SettingsKey.Default.virtualDisplay
    @AppStorage(SettingsKey.autoCheckUpdates) private var autoCheckUpdates = SettingsKey.Default.autoCheckUpdates

    var body: some View {
        Form {
            Section("Imagem") {
                Picker("Qualidade", selection: $quality) {
                    ForEach(Quality.allCases) { Text($0.title).tag($0) }
                }
                Picker("Codec de vídeo", selection: $codec) {
                    ForEach(Codec.allCases) { Text($0.title).tag($0) }
                }
            }

            Section("Durante o espelhamento") {
                Toggle("Apagar a tela do Galaxy", isOn: $turnScreenOff)
                    .disabled(virtualDisplay)
                Toggle("Reproduzir o áudio do Galaxy no Mac", isOn: $audio)
                Toggle("Impedir que o Galaxy entre em repouso", isOn: $stayAwake)
                Toggle("Manter a janela sempre na frente", isOn: $alwaysOnTop)
                Toggle("Bloquear o Galaxy ao encerrar", isOn: $lockOnClose)
            }

            Section {
                Toggle("Espelhar automaticamente ao abrir o app", isOn: $autoStart)
                Toggle("Usar uma tela independente", isOn: $virtualDisplay)
            } header: {
                Text("Geral")
            } footer: {
                Text("A tela independente abre os apps numa tela virtual, sem mexer no que aparece no celular. Recurso experimental.")
                    .foregroundStyle(.secondary)
            }

            Section("Dispositivo") {
                LabeledContent("Celular", value: app.pairedDevice?.name ?? "Nenhum")
                if let address = app.pairedDevice?.lastAddress {
                    LabeledContent("Último endereço", value: address)
                }
                Button("Esquecer este Galaxy…", role: .destructive) { app.forget() }
                    .disabled(app.pairedDevice == nil)
            }

            Section {
                Toggle("Verificar atualizações automaticamente", isOn: $autoCheckUpdates)
                LabeledContent("Versão instalada", value: updates.currentVersion)
                LabeledContent("Última verificação") {
                    if let lastCheck = updates.lastCheck {
                        Text(lastCheck, format: .dateTime.day().month().hour().minute())
                    } else {
                        Text("Nunca")
                    }
                }
                HStack {
                    Button("Verificar Agora") { updates.checkNow() }
                        .disabled(updates.isChecking)
                    if updates.isChecking {
                        ProgressView().controlSize(.small)
                    }
                }
            } header: {
                Text("Atualizações")
            } footer: {
                Text("No modo automático, o app verifica ao abrir e uma vez por dia. As novas versões são baixadas da página de Releases no GitHub.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 480)
        .fixedSize(horizontal: false, vertical: true)
    }
}
