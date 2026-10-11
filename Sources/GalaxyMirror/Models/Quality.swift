import Foundation

enum Quality: String, CaseIterable, Identifiable {
    case max, high, medium, low

    var id: String { rawValue }

    var title: String {
        switch self {
        case .max: String(localized: "Máxima")
        case .high: String(localized: "Alta")
        case .medium: String(localized: "Média")
        case .low: String(localized: "Econômica")
        }
    }

    var maxSize: Int? {
        switch self {
        case .max: nil
        case .high: 1920
        case .medium: 1440
        case .low: 1024
        }
    }

    var bitRate: Int {
        switch self {
        case .max: 16_000_000
        case .high: 12_000_000
        case .medium: 8_000_000
        case .low: 4_000_000
        }
    }
}
