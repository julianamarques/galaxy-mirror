import Testing
@testable import GalaxyMirror

struct ScrcpyTests {
    @Test(arguments: [
        "INFO: Renderer: metal\nINFO: Texture: 886x1920\n",
        "INFO: Renderer: metal\nINFO: Video decoding: videotoolbox\nINFO: Texture (VideoToolbox): 886x1920\n",
    ])
    func detectsFirstFrame(log: String) {
        #expect(Scrcpy.hasFirstFrame(inLog: log))
    }

    @Test func ignoresLogsWithoutVideo() {
        let log = "INFO: ADB device found:\n[server] INFO: Device: [samsung] samsung SM-S931B (Android 16)\nINFO: Renderer: metal\n"

        #expect(!Scrcpy.hasFirstFrame(inLog: log))
    }
}
