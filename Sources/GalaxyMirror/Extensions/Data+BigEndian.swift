import Foundation

extension Data {
    mutating func append<T: FixedWidthInteger>(bigEndian value: T) {
        Swift.withUnsafeBytes(of: value.bigEndian) { append(contentsOf: $0) }
    }
}
