import Foundation

enum SettingsKey {
    static let quality = "quality"
    static let codec = "codec"
    static let turnScreenOff = "turnScreenOff"
    static let audio = "audio"
    static let stayAwake = "stayAwake"
    static let alwaysOnTop = "alwaysOnTop"
    static let lockOnClose = "lockOnClose"
    static let autoStart = "autoStart"
    static let virtualDisplay = "virtualDisplay"
    static let autoCheckUpdates = "autoCheckUpdates"
    static let lastUpdateCheck = "lastUpdateCheck"
    static let skippedUpdateVersion = "skippedUpdateVersion"

    enum Default {
        static let quality = Quality.high
        static let codec = Codec.h264
        static let turnScreenOff = false
        static let audio = true
        static let stayAwake = true
        static let alwaysOnTop = false
        static let lockOnClose = false
        static let autoStart = true
        static let virtualDisplay = false
        static let autoCheckUpdates = true
    }

    static var defaults: [String: Any] {
        [
            quality: Default.quality.rawValue,
            codec: Default.codec.rawValue,
            turnScreenOff: Default.turnScreenOff,
            audio: Default.audio,
            stayAwake: Default.stayAwake,
            alwaysOnTop: Default.alwaysOnTop,
            lockOnClose: Default.lockOnClose,
            autoStart: Default.autoStart,
            virtualDisplay: Default.virtualDisplay,
            autoCheckUpdates: Default.autoCheckUpdates,
        ]
    }

    static func register() {
        UserDefaults.standard.register(defaults: defaults)
    }
}
