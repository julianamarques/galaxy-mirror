import Foundation

enum ScrcpyProtocol {
    static let serverVersion = "5.0"
    static let devicePath = "/data/local/tmp/scrcpy-server.jar"
    static let deviceNameLength = 64
    static let headerLength = 12
    static let rawAudioCodecID: UInt32 = 0x0072_6177

    enum Header: Equatable {
        case session(width: Int, height: Int)
        case media(isConfig: Bool, isKeyFrame: Bool, pts: UInt64, size: Int)
    }

    static func parseHeader(_ bytes: [UInt8]) -> Header? {
        guard bytes.count == headerLength else { return nil }
        if bytes[0] & 0x80 != 0 {
            return .session(width: Int(bytes.bigEndian(at: 4, as: UInt32.self)), height: Int(bytes.bigEndian(at: 8, as: UInt32.self)))
        }
        let ptsAndFlags = bytes.bigEndian(at: 0, as: UInt64.self)
        return .media(
            isConfig: ptsAndFlags & (1 << 62) != 0,
            isKeyFrame: ptsAndFlags & (1 << 61) != 0,
            pts: ptsAndFlags & ((1 << 61) - 1),
            size: Int(bytes.bigEndian(at: 8, as: UInt32.self))
        )
    }
}
