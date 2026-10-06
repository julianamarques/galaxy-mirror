import Foundation

extension String {
    static func random(_ length: Int) -> String {
        let chars = Array("abcdefghijkmnpqrstuvwxyz23456789")
        return String((0..<length).map { _ in chars.randomElement()! })
    }
}
