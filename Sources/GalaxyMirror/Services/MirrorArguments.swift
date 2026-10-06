import Foundation

enum MirrorArguments {
    static func make(serial: String, title: String, defaults: UserDefaults = .standard) -> [String] {
        let quality = defaults.string(forKey: SettingsKey.quality).flatMap(Quality.init(rawValue:)) ?? SettingsKey.Default.quality
        let codec = defaults.string(forKey: SettingsKey.codec).flatMap(Codec.init(rawValue:)) ?? SettingsKey.Default.codec

        var args = [
            "--serial=\(serial)",
            "--window-title=\(title)",
            "--video-codec=\(codec.rawValue)",
            "--video-bit-rate=\(quality.bitRate)",
            "--no-terminal-title",
        ]
        if let size = quality.maxSize { args.append("--max-size=\(size)") }
        if !defaults.bool(forKey: SettingsKey.audio) { args.append("--no-audio") }
        if defaults.bool(forKey: SettingsKey.stayAwake) { args.append("--stay-awake") }
        if defaults.bool(forKey: SettingsKey.alwaysOnTop) { args.append("--always-on-top") }
        if defaults.bool(forKey: SettingsKey.lockOnClose) { args.append("--power-off-on-close") }
        if defaults.bool(forKey: SettingsKey.virtualDisplay) {
            args.append("--new-display")
        } else if defaults.bool(forKey: SettingsKey.turnScreenOff) {
            args.append("--turn-screen-off")
        }
        return args
    }
}
