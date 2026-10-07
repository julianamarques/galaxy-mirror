import Testing
@testable import GalaxyMirror

struct ScrcpyProtocolTests {
    @Test func parsesSessionPacket() {
        let bytes: [UInt8] = [0x80, 0, 0, 0, 0, 0, 0x03, 0x76, 0, 0, 0x07, 0x80]

        #expect(ScrcpyProtocol.parseHeader(bytes) == .session(width: 886, height: 1920))
    }

    @Test func parsesConfigPacket() {
        let bytes: [UInt8] = [0x40, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x1A]

        #expect(ScrcpyProtocol.parseHeader(bytes) == .media(isConfig: true, isKeyFrame: false, pts: 0, size: 26))
    }

    @Test func parsesKeyFramePacket() {
        let bytes: [UInt8] = [0x20, 0, 0, 0, 0, 0x0F, 0x42, 0x40, 0, 0x01, 0, 0]

        #expect(ScrcpyProtocol.parseHeader(bytes) == .media(isConfig: false, isKeyFrame: true, pts: 1_000_000, size: 65536))
    }

    @Test func rejectsShortHeaders() {
        #expect(ScrcpyProtocol.parseHeader([0, 1, 2]) == nil)
    }

    @Test func mapsVideoCodecIDs() {
        #expect(Codec(scrcpyID: 0x6832_3634) == .h264)
        #expect(Codec(scrcpyID: 0x6832_3635) == .h265)
        #expect(Codec(scrcpyID: 0x0061_7631) == nil)
        #expect(Codec(scrcpyID: 0) == nil)
    }
}
