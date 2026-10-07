import Foundation

enum ControlMessage {
    struct Position: Equatable {
        var x: Int32
        var y: Int32
        var screenWidth: UInt16
        var screenHeight: UInt16
    }

    enum KeyAction: UInt8 {
        case down = 0
        case up = 1
    }

    enum TouchAction: UInt8 {
        case down = 0
        case up = 1
        case move = 2
    }

    static let mousePointerID = UInt64.max
    static let primaryButton: Int32 = 1
    static let textLimit = 300

    case keycode(action: KeyAction, keycode: Int32, repeatCount: Int32 = 0, metaState: Int32 = 0)
    case text(String)
    case touch(action: TouchAction, pointerID: UInt64, position: Position, pressure: Float, actionButton: Int32, buttons: Int32)
    case scroll(position: Position, horizontal: Float, vertical: Float, buttons: Int32)
    case backOrScreenOn(action: KeyAction)
    case setClipboard(sequence: UInt64, text: String, paste: Bool)
    case setDisplayPower(on: Bool)
    case resetVideo

    var data: Data {
        var data = Data()
        switch self {
        case let .keycode(action, keycode, repeatCount, metaState):
            data.append(0)
            data.append(action.rawValue)
            data.append(bigEndian: keycode)
            data.append(bigEndian: repeatCount)
            data.append(bigEndian: metaState)
        case let .text(text):
            data.append(1)
            data.appendString(Self.truncated(text, toBytes: Self.textLimit))
        case let .touch(action, pointerID, position, pressure, actionButton, buttons):
            data.append(2)
            data.append(action.rawValue)
            data.append(bigEndian: pointerID)
            data.append(position)
            data.append(bigEndian: Self.unsignedFixedPoint(pressure))
            data.append(bigEndian: actionButton)
            data.append(bigEndian: buttons)
        case let .scroll(position, horizontal, vertical, buttons):
            data.append(3)
            data.append(position)
            data.append(bigEndian: Self.signedFixedPoint(horizontal / 16))
            data.append(bigEndian: Self.signedFixedPoint(vertical / 16))
            data.append(bigEndian: buttons)
        case let .backOrScreenOn(action):
            data.append(4)
            data.append(action.rawValue)
        case let .setClipboard(sequence, text, paste):
            data.append(9)
            data.append(bigEndian: sequence)
            data.append(paste ? 1 : 0)
            data.appendString(text)
        case let .setDisplayPower(on):
            data.append(10)
            data.append(on ? 1 : 0)
        case .resetVideo:
            data.append(17)
        }
        return data
    }

    static func unsignedFixedPoint(_ value: Float) -> UInt16 {
        let clamped = min(max(value, 0), 1)
        return clamped >= 1 ? 0xFFFF : UInt16(clamped * 65536)
    }

    static func signedFixedPoint(_ value: Float) -> Int16 {
        let clamped = min(max(value, -1), 1)
        return clamped >= 1 ? 0x7FFF : Int16(clamped * 32768)
    }

    static func truncated(_ text: String, toBytes limit: Int) -> String {
        var result = ""
        var count = 0
        for character in text {
            let size = character.utf8.count
            guard count + size <= limit else { break }
            result.append(character)
            count += size
        }
        return result
    }
}

private extension Data {
    mutating func append(_ position: ControlMessage.Position) {
        append(bigEndian: position.x)
        append(bigEndian: position.y)
        append(bigEndian: position.screenWidth)
        append(bigEndian: position.screenHeight)
    }

    mutating func appendString(_ text: String) {
        let bytes = Array(text.utf8)
        append(bigEndian: UInt32(bytes.count))
        append(contentsOf: bytes)
    }
}
