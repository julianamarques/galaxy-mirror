import Foundation
import Testing
@testable import GalaxyMirror

struct MirrorArgumentsTests {
    private func makeDefaults(_ values: [String: Any] = [:]) -> UserDefaults {
        let suite = "GalaxyMirrorTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.register(defaults: SettingsKey.defaults)
        values.forEach { defaults.set($1, forKey: $0) }
        return defaults
    }

    @Test func usesDefaultSettings() {
        let args = MirrorArguments.make(serial: "192.168.0.10:41235", title: "Galaxy S25", defaults: makeDefaults())

        #expect(args.contains("--serial=192.168.0.10:41235"))
        #expect(args.contains("--window-title=Galaxy S25"))
        #expect(args.contains("--video-codec=h264"))
        #expect(args.contains("--max-size=1920"))
        #expect(args.contains("--video-bit-rate=12M"))
        #expect(args.contains("--turn-screen-off"))
        #expect(args.contains("--stay-awake"))
        #expect(!args.contains("--no-audio"))
        #expect(!args.contains("--new-display"))
    }

    @Test func maximumQualityHasNoSizeLimit() {
        let args = MirrorArguments.make(serial: "s", title: "t", defaults: makeDefaults([SettingsKey.quality: Quality.max.rawValue]))

        #expect(!args.contains { $0.hasPrefix("--max-size") })
        #expect(args.contains("--video-bit-rate=16M"))
    }

    @Test func virtualDisplayKeepsPhoneScreenOn() {
        let args = MirrorArguments.make(serial: "s", title: "t", defaults: makeDefaults([SettingsKey.virtualDisplay: true]))

        #expect(args.contains("--new-display"))
        #expect(!args.contains("--turn-screen-off"))
    }

    @Test func disablesAudio() {
        let args = MirrorArguments.make(serial: "s", title: "t", defaults: makeDefaults([SettingsKey.audio: false]))

        #expect(args.contains("--no-audio"))
    }
}
