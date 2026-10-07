import Foundation

extension Array where Element == UInt8 {
    func bigEndian<T: FixedWidthInteger>(at offset: Int, as type: T.Type = T.self) -> T {
        self[offset..<offset + MemoryLayout<T>.size].reduce(0) { $0 << 8 | T($1) }
    }
}
