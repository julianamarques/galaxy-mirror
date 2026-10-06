import AppKit
import SwiftUI

struct SetupFlowView: View {
    @ObservedObject var setup: SetupModel
    @EnvironmentObject private var app: AppModel
    @Environment(\.openURL) private var openURL

    var body: some View {
        Group {
            switch setup.step {
            case .welcome: welcome
            case .missingTools: missingTools
            case .prepare: prepare
            case .pair: PairingView(setup: setup)
            case .connecting: connecting
            case .failed(let detail): failed(detail)
            case .done: done
            }
        }
        .animation(.easeInOut(duration: 0.25), value: setup.step)
    }

    private var welcome: some View {
        SetupPage(title: "Espelhamento do Galaxy") {
            MirrorIllustration()
        } content: {
            Text("Use seu Galaxy diretamente do Mac. Veja a tela, abra seus apps e digite com o teclado do Mac — tudo sem fio, pela sua rede Wi-Fi.")
        } buttons: {
            PillButton("Saiba Mais…") { openURL(Links.learnMore) }
            Spacer()
            PillButton("Agora Não") { NSApp.terminate(nil) }
            PillButton("Continuar", prominent: true) { setup.continueFromWelcome() }
        }
    }

    private var missingTools: some View {
        SetupPage(title: "Faltam alguns componentes") {
            MirrorIllustration()
        } content: {
            VStack(alignment: .leading, spacing: 10) {
                Text("O Espelhamento do Galaxy usa o adb e o scrcpy para se comunicar com o celular. Instale-os pelo Homebrew no Terminal:")
                HStack {
                    Text(installCommand)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)
                    Spacer()
                    Button("Copiar") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(installCommand, forType: .string)
                    }
                    .font(.body)
                }
                .padding(10)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
            }
        } buttons: {
            PillButton("Saiba Mais…") { openURL(Links.homebrew) }
            Spacer()
            PillButton("Agora Não") { NSApp.terminate(nil) }
            PillButton("Tentar Novamente", prominent: true) { setup.continueFromWelcome() }
        }
    }

    private var installCommand: String { "brew install scrcpy android-platform-tools" }

    private var prepare: some View {
        SetupPage(title: "Prepare seu Galaxy") {
            MirrorIllustration()
        } content: {
            NumberedSteps(steps: [
                "Abra **Configurações › Sobre o telefone › Informações do software** e toque 7 vezes em **Número de compilação**.",
                "Volte para **Configurações › Opções do desenvolvedor** e ative a **Depuração sem fio**.",
                "Conecte o Galaxy à mesma rede Wi-Fi deste Mac.",
            ])
            .font(.body)
        } buttons: {
            PillButton("Saiba Mais…") { openURL(Links.learnMore) }
            Spacer()
            PillButton("Voltar") { setup.cancel() }
            PillButton("Continuar", prominent: true) { setup.beginPairing() }
        }
    }

    private var connecting: some View {
        SetupPage(title: "Conectando ao Galaxy…") {
            MirrorIllustration(status: .searching)
        } content: {
            ProgressLabel("Pareamento concluído. Estabelecendo a conexão sem fio.")
        } buttons: {
            Spacer()
            PillButton("Cancelar") { setup.cancel() }
        }
    }

    private func failed(_ detail: String) -> some View {
        SetupPage(title: "Não é possível conectar ao Galaxy") {
            MirrorIllustration()
        } content: {
            VStack(alignment: .leading, spacing: 8) {
                Text("Para configurar o Espelhamento do Galaxy, assegure-se de que o celular esteja ligado, desbloqueado, conectado à mesma rede Wi-Fi que este Mac e com a Depuração sem fio ativada nas Opções do desenvolvedor.")
                ErrorDetail(detail)
            }
        } buttons: {
            PillButton("Saiba Mais…") { openURL(Links.learnMore) }
            Spacer()
            PillButton("Agora Não") { setup.cancel() }
            PillButton("Tentar Novamente", prominent: true) { setup.retry() }
        }
    }

    private var done: some View {
        SetupPage(title: "Tudo pronto") {
            MirrorIllustration(status: .connected)
        } content: {
            Text("O \(app.deviceName) está pronto. Use o trackpad e o teclado do Mac para controlar o celular — a tela dele fica apagada enquanto você usa.")
        } buttons: {
            SettingsPillLink()
            Spacer()
            PillButton("Agora Não") { app.finishSetup(startMirroring: false) }
            PillButton("Começar a Espelhar", prominent: true) { app.finishSetup(startMirroring: true) }
        }
    }
}
