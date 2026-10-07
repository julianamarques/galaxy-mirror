import AppKit

enum AndroidKeycode: Int32 {
    case home = 3
    case back = 4
    case dpadUp = 19
    case dpadDown = 20
    case dpadLeft = 21
    case dpadRight = 22
    case tab = 61
    case enter = 66
    case delete = 67
    case pageUp = 92
    case pageDown = 93
    case escape = 111
    case forwardDelete = 112
    case moveHome = 122
    case moveEnd = 123
    case appSwitch = 187

    init?(macKeyCode: UInt16) {
        switch macKeyCode {
        case 36, 76: self = .enter
        case 48: self = .tab
        case 51: self = .delete
        case 53: self = .escape
        case 115: self = .moveHome
        case 116: self = .pageUp
        case 117: self = .forwardDelete
        case 119: self = .moveEnd
        case 121: self = .pageDown
        case 123: self = .dpadLeft
        case 124: self = .dpadRight
        case 125: self = .dpadDown
        case 126: self = .dpadUp
        default: return nil
        }
    }

    static func metaState(for flags: NSEvent.ModifierFlags) -> Int32 {
        var state: Int32 = 0
        if flags.contains(.shift) { state |= 0x41 }
        if flags.contains(.option) { state |= 0x12 }
        if flags.contains(.control) { state |= 0x3000 }
        if flags.contains(.command) { state |= 0x30000 }
        return state
    }
}
