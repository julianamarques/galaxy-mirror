import Foundation

enum ToolError: LocalizedError, Equatable {
    case missing(String)
    case failed(String)
    case timeout
    case phoneHotspot
    case differentNetwork(mac: String?, phone: String)
    case usbNotConnected
    case mirrorTimeout

    var errorDescription: String? {
        switch self {
        case .missing(let name): "O componente “\(name)” não foi encontrado."
        case .failed(let message): message
        case .timeout: "O Galaxy não respondeu a tempo."
        case .phoneHotspot: "O Mac está conectado ao hotspot do Galaxy."
        case .differentNetwork(_, let phone): "O Galaxy (\(phone)) está em outra rede."
        case .usbNotConnected: "O Galaxy não está conectado por cabo USB."
        case .mirrorTimeout: "O Galaxy não começou a enviar a imagem."
        }
    }
}
