import Foundation

enum Codec: String, CaseIterable, Identifiable {
    case h264, h265, av1

    var id: String { rawValue }

    var title: String {
        switch self {
        case .h264: "H.264 (mais compatível)"
        case .h265: "H.265 (melhor qualidade)"
        case .av1: "AV1"
        }
    }
}
