import Foundation

struct ConnectionProblem: Equatable {
    let title: String
    let message: String
    let detail: String?
    let suggestsUSB: Bool

    init(_ error: Error) {
        switch error as? ToolError {
        case .phoneHotspot:
            title = "O Mac está usando o hotspot do Galaxy"
            message = "A Depuração sem fio não funciona quando o Mac está conectado ao Ponto de acesso móvel do próprio celular. Conecte o Mac e o Galaxy à mesma rede Wi-Fi ou use um cabo USB."
            detail = nil
            suggestsUSB = true
        case .differentNetwork(let mac, let phone):
            title = "O Mac e o Galaxy estão em redes diferentes"
            let location = mac.map { "O Galaxy está em \(phone) e o Mac em \($0)." } ?? "O Galaxy está em \(phone), fora da rede deste Mac."
            message = "\(location) Conecte os dois à mesma rede Wi-Fi ou use um cabo USB. O Ponto de acesso móvel do próprio Galaxy não funciona para a Depuração sem fio."
            detail = nil
            suggestsUSB = true
        case .usbNotConnected:
            title = "Conecte o Galaxy pelo cabo USB"
            message = "Este Galaxy foi configurado por cabo. Conecte-o ao Mac com um cabo USB e verifique se a Depuração USB está ativada nas Opções do desenvolvedor."
            detail = nil
            suggestsUSB = false
        case .mirrorTimeout:
            title = "O Galaxy não enviou a imagem"
            message = "A conexão Wi-Fi com o celular está perdendo muitos dados. Aproxime o Galaxy do roteador, desligue o Ponto de acesso móvel dele ou conecte um cabo USB e tente de novo."
            detail = nil
            suggestsUSB = true
        default:
            title = "Não é possível conectar ao Galaxy"
            message = "Assegure-se de que o Galaxy esteja ligado, desbloqueado, conectado à mesma rede Wi-Fi que este Mac e com a Depuração sem fio ativada nas Opções do desenvolvedor."
            detail = error.localizedDescription
            suggestsUSB = false
        }
    }
}
