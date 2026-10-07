import Foundation

enum DeviceMessage: Equatable {
    enum ParseError: Error {
        case unknownType(UInt8)
    }

    case clipboard(String)
    case clipboardAck

    static func read(using read: (Int) throws -> [UInt8]) throws -> DeviceMessage {
        let type = try read(1)[0]
        switch type {
        case 0:
            let length = Int(try read(4).bigEndian(at: 0, as: UInt32.self))
            return .clipboard(String(decoding: try read(length), as: UTF8.self))
        case 1:
            _ = try read(8)
            return .clipboardAck
        default:
            throw ParseError.unknownType(type)
        }
    }
}
