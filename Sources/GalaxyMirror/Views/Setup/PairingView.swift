import SwiftUI

struct PairingView: View {
    @ObservedObject var setup: SetupModel

    var body: some View {
        SetupPage(title: setup.mode == .qr ? "Escaneie com o Galaxy" : "Parear com código") {
            if setup.mode == .qr { qrHeader } else { codeHeader }
        } content: {
            if setup.mode == .qr { qrSteps } else { codeSteps }
        } buttons: {
            HStack(spacing: 16) {
                Button(setup.mode == .qr ? "Usar código de seis dígitos" : "Usar QR code") {
                    setup.mode = setup.mode == .qr ? .code : .qr
                }
                Button("Usar cabo USB") { setup.beginUSB() }
            }
            .buttonStyle(.link)
            .controlSize(.regular)
            Spacer()
            PillButton("Cancelar") { setup.cancel() }
            if setup.mode == .code {
                PillButton("Parear", prominent: true) { setup.submitCode() }
                    .disabled(!setup.canSubmitCode)
            }
        }
    }

    private var qrHeader: some View {
        QRCodeView(payload: setup.qrPayload)
            .frame(width: 210, height: 210)
            .padding(14)
            .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                if setup.isPairing {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.regularMaterial)
                        .overlay(ProgressView("Pareando…"))
                }
            }
            .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
    }

    private var qrSteps: some View {
        VStack(alignment: .leading, spacing: 14) {
            NumberedSteps(steps: [
                "No Galaxy, abra **Opções do desenvolvedor › Depuração sem fio**.",
                "Toque em **Parear dispositivo com código QR** e aponte a câmera para o código acima.",
            ])
            .font(.body)
            ProgressLabel("Aguardando o Galaxy na rede…").font(.callout)
        }
    }

    private var codeHeader: some View {
        VStack(spacing: 18) {
            GalaxyPhone()
            TextField("000000", text: $setup.code)
                .font(.system(size: 34, weight: .semibold, design: .monospaced))
                .multilineTextAlignment(.center)
                .textFieldStyle(.plain)
                .frame(width: 220)
                .padding(.vertical, 8)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
                .onSubmit { setup.submitCode() }
        }
    }

    private var codeSteps: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Em **Depuração sem fio**, toque em **Parear dispositivo com código de pareamento** e digite aqui o código de seis dígitos.")
                .font(.body)

            if setup.discovered.count > 1 {
                Picker("Celular", selection: $setup.selectedAddress) {
                    ForEach(setup.discovered) { service in
                        Text(service.address).tag(Optional(service.address))
                    }
                }
                .font(.body)
            } else if let address = setup.selectedAddress {
                Label("Galaxy encontrado em \(address)", systemImage: "checkmark.circle.fill")
                    .font(.callout)
                    .foregroundStyle(.green)
            } else {
                ProgressLabel("Procurando… ou informe o endereço exibido no Galaxy:").font(.callout)
                TextField("IP e porta, ex.: 192.168.0.10:37123", text: $setup.manualAddress)
                    .textFieldStyle(.roundedBorder)
                    .font(.body)
            }

            if let error = setup.codeError {
                Text(error)
                    .font(.callout)
                    .foregroundStyle(.red)
                    .lineLimit(3)
            }
        }
    }
}
