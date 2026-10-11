import Foundation

enum Codec: String, CaseIterable, Identifiable {
    case h264, h265

    var id: String { rawValue }

    var title: String {
        switch self {
        case .h264: String(localized: "H.264 (mais compatível)")
        case .h265: String(localized: "H.265 (melhor qualidade)")
        }
    }

    init?(scrcpyID: UInt32) {
        switch scrcpyID {
        case 0x6832_3634: self = .h264
        case 0x6832_3635: self = .h265
        default: return nil
        }
    }
}
