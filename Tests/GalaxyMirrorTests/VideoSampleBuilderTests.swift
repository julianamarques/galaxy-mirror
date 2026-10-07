import Foundation
import CoreMedia
import Testing
@testable import GalaxyMirror

struct VideoSampleBuilderTests {
    private let sps: [UInt8] = [0x67, 0x42, 0xC0, 0x0D, 0xD9, 0x01, 0x41, 0xFB, 0x01, 0x10, 0x00, 0x00, 0x03, 0x00, 0x10, 0x00, 0x00, 0x03, 0x03, 0x20, 0xF1, 0x42, 0xA4, 0x80]
    private let pps: [UInt8] = [0x68, 0xCB, 0x83, 0xCB, 0x20]

    @Test func splitsAnnexBUnits() {
        let data: [UInt8] = [0, 0, 0, 1, 0x67, 0xAA, 0, 0, 1, 0x68, 0xBB, 0, 0, 0, 1, 0x65, 0xCC, 0xDD]

        #expect(VideoSampleBuilder.nalUnits(in: data) == [4..<6, 9..<11, 15..<18])
    }

    @Test func ignoresDataWithoutStartCodes() {
        #expect(VideoSampleBuilder.nalUnits(in: [0x65, 0x01, 0x02]).isEmpty)
    }

    @Test func buildsFormatAndSamplesFromH264() throws {
        let builder = VideoSampleBuilder(codec: .h264)
        let config = [0, 0, 0, 1] + sps + [0, 0, 0, 1] + pps

        try builder.applyConfig(config)
        let dimensions = CMVideoFormatDescriptionGetDimensions(try #require(builder.format))
        #expect(dimensions.width == 320)
        #expect(dimensions.height == 240)

        let sample = try #require(try builder.sampleBuffer([0, 0, 0, 1, 0x65, 0x88, 0x84], pts: 33_333, isKeyFrame: true))
        #expect(sample.totalSampleSize == 7)
        #expect(sample.presentationTimeStamp.seconds == 0.033333)
        #expect(try sample.dataBuffer?.dataBytes() == Data([0, 0, 0, 3, 0x65, 0x88, 0x84]))
        #expect(sample.sampleAttachments[0][.notSync] == nil)

        let delta = try #require(try builder.sampleBuffer([0, 0, 1, 0x41, 0x9A], pts: 66_666, isKeyFrame: false))
        #expect(delta.sampleAttachments[0][.notSync] as? Bool == true)
    }

    @Test func requiresParameterSetsInConfig() {
        #expect(throws: VideoSampleBuilder.BuildError.self) {
            try VideoSampleBuilder(codec: .h264).applyConfig([0, 0, 0, 1, 0x65, 0x01])
        }
    }

    @Test func detectsParameterSetsPerCodec() {
        let h264 = VideoSampleBuilder(codec: .h264)
        let h265 = VideoSampleBuilder(codec: .h265)

        #expect(h264.isParameterSet(0x67))
        #expect(!h264.isParameterSet(0x65))
        #expect(h265.isParameterSet(0x40))
        #expect(!h265.isParameterSet(0x26))
    }
}
