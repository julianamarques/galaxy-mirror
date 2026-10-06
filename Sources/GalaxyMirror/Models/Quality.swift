import Foundation

enum Quality: String, CaseIterable, Identifiable {
    case max, high, medium, low

    var id: String { rawValue }

    var title: String {
        switch self {
        case .max: "Máxima"
        case .high: "Alta"
        case .medium: "Média"
        case .low: "Econômica"
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

    var bitRate: String {
        switch self {
        case .max: "16M"
        case .high: "12M"
        case .medium: "8M"
        case .low: "4M"
        }
    }
}
