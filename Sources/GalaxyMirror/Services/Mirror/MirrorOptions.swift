import Foundation

struct MirrorOptions {
    var quality: Quality
    var codec: Codec
    var audio: Bool
    var turnScreenOff: Bool
    var stayAwake: Bool
    var alwaysOnTop: Bool
    var lockOnClose: Bool
    var virtualDisplay: Bool

    init(defaults: UserDefaults = .standard) {
        quality = defaults.string(forKey: SettingsKey.quality).flatMap(Quality.init(rawValue:)) ?? SettingsKey.Default.quality
        codec = defaults.string(forKey: SettingsKey.codec).flatMap(Codec.init(rawValue:)) ?? SettingsKey.Default.codec
        audio = defaults.bool(forKey: SettingsKey.audio)
        virtualDisplay = defaults.bool(forKey: SettingsKey.virtualDisplay)
        turnScreenOff = defaults.bool(forKey: SettingsKey.turnScreenOff) && !virtualDisplay
        stayAwake = defaults.bool(forKey: SettingsKey.stayAwake)
        alwaysOnTop = defaults.bool(forKey: SettingsKey.alwaysOnTop)
        lockOnClose = defaults.bool(forKey: SettingsKey.lockOnClose)
    }

    var serverArguments: [String] {
        var args = [
            "log_level=info",
            "tunnel_forward=true",
            "video_codec=\(codec.rawValue)",
            "video_bit_rate=\(quality.bitRate)",
            audio ? "audio_codec=raw" : "audio=false",
        ]
        if let size = quality.maxSize { args.append("max_size=\(size)") }
        if stayAwake { args.append("stay_awake=true") }
        if lockOnClose { args.append("power_off_on_close=true") }
        if virtualDisplay { args.append("new_display=") }
        return args
    }
}
