import Foundation

enum ToolError: LocalizedError {
    case missing(String)
    case failed(String)
    case timeout

    var errorDescription: String? {
        switch self {
        case .missing(let name): "O componente “\(name)” não foi encontrado."
        case .failed(let message): message
        case .timeout: "O Galaxy não respondeu a tempo."
        }
    }
}
