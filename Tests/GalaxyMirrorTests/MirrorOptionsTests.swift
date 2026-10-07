import Foundation
import Testing
@testable import GalaxyMirror

struct MirrorOptionsTests {
    private func makeDefaults(_ values: [String: Any] = [:]) -> UserDefaults {
        let defaults = UserDefaults(suiteName: "GalaxyMirrorTests.\(UUID().uuidString)")!
        defaults.register(defaults: SettingsKey.defaults)
        values.forEach { defaults.set($1, forKey: $0) }
        return defaults
    }

    @Test func usesDefaultSettings() {
        let args = MirrorOptions(defaults: makeDefaults()).serverArguments

        #expect(args.contains("tunnel_forward=true"))
        #expect(args.contains("video_codec=h264"))
        #expect(args.contains("video_bit_rate=12000000"))
        #expect(args.contains("max_size=1920"))
        #expect(args.contains("audio_codec=raw"))
        #expect(args.contains("stay_awake=true"))
        #expect(!args.contains("new_display="))
    }

    @Test func disablesAudio() {
        let args = MirrorOptions(defaults: makeDefaults([SettingsKey.audio: false])).serverArguments

        #expect(args.contains("audio=false"))
        #expect(!args.contains("audio_codec=raw"))
    }

    @Test func maximumQualityHasNoSizeLimit() {
        let args = MirrorOptions(defaults: makeDefaults([SettingsKey.quality: Quality.max.rawValue])).serverArguments

        #expect(!args.contains { $0.hasPrefix("max_size") })
        #expect(args.contains("video_bit_rate=16000000"))
    }

    @Test func virtualDisplayKeepsPhoneScreenOn() {
        let options = MirrorOptions(defaults: makeDefaults([SettingsKey.virtualDisplay: true, SettingsKey.turnScreenOff: true]))

        #expect(options.serverArguments.contains("new_display="))
        #expect(!options.turnScreenOff)
    }

    @Test func fallsBackFromRemovedCodec() {
        #expect(MirrorOptions(defaults: makeDefaults([SettingsKey.codec: "av1"])).codec == .h264)
    }
}
