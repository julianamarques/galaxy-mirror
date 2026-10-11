import Foundation

struct ConnectionProblem: Equatable {
    let title: String
    let message: String
    let detail: String?
    let suggestsUSB: Bool
    var needsLocalNetworkPermission = false

    init(_ error: Error) {
        switch error as? ToolError {
        case .phoneHotspot:
            title = String(localized: "O Mac está usando o hotspot do Galaxy")
            message = String(localized: "A Depuração sem fio não funciona quando o Mac está conectado ao Ponto de acesso móvel do próprio celular. Conecte o Mac e o Galaxy à mesma rede Wi-Fi ou use um cabo USB.")
            detail = nil
            suggestsUSB = true
        case .differentNetwork(let mac, let phone):
            title = String(localized: "O Mac e o Galaxy estão em redes diferentes")
            let location = mac.map { String(localized: "O Galaxy está em \(phone) e o Mac em \($0).") } ?? String(localized: "O Galaxy está em \(phone), fora da rede deste Mac.")
            message = String(localized: "\(location) Conecte os dois à mesma rede Wi-Fi ou use um cabo USB. O Ponto de acesso móvel do próprio Galaxy não funciona para a Depuração sem fio.")
            detail = nil
            suggestsUSB = true
        case .usbNotConnected:
            title = String(localized: "O Galaxy não está conectado")
            message = String(localized: "Este Galaxy foi configurado só pelo cabo. Conecte-o ao Mac com um cabo USB ou clique em Configurar Wi-Fi para usá-lo também sem fio.")
            detail = nil
            suggestsUSB = false
        case .localNetworkDenied:
            title = String(localized: "Permita o acesso à Rede Local")
            message = String(localized: "O macOS está impedindo o Galaxy Mirror de encontrar o Galaxy pelo Wi-Fi. Em Ajustes do Sistema › Privacidade e Segurança › Rede Local, ative o Galaxy Mirror.")
            detail = nil
            suggestsUSB = false
            needsLocalNetworkPermission = true
        case .mirrorTimeout:
            title = String(localized: "O Galaxy não enviou a imagem")
            message = String(localized: "A conexão Wi-Fi com o celular está perdendo muitos dados. Aproxime o Galaxy do roteador, desligue o Ponto de acesso móvel dele ou conecte um cabo USB e tente de novo.")
            detail = nil
            suggestsUSB = true
        default:
            title = String(localized: "Não é possível conectar ao Galaxy")
            message = String(localized: "Assegure-se de que o Galaxy esteja ligado, desbloqueado, conectado à mesma rede Wi-Fi que este Mac e com a Depuração sem fio ativada nas Opções do desenvolvedor.")
            detail = error.localizedDescription
            suggestsUSB = false
        }
    }
}
