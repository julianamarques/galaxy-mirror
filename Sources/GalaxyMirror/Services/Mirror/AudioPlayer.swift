import Accelerate
import AVFoundation

final class AudioPlayer: @unchecked Sendable {
    static let sampleRate = 48_000.0
    static let channels: AVAudioChannelCount = 2
    private static let maxQueuedFrames = AVAudioFramePosition(sampleRate * 0.2)

    private let engine = AVAudioEngine()
    private let node = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: channels)!
    private let lock = NSLock()
    private var queuedFrames: AVAudioFramePosition = 0

    func start() throws {
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        try engine.start()
        node.play()
    }

    func play(interleavedInt16 bytes: [UInt8]) {
        let frameCount = AVAudioFrameCount(bytes.count / (2 * Int(Self.channels)))
        guard frameCount > 0, reserve(frameCount) else { return }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channels = buffer.floatChannelData
        else {
            release(frameCount)
            return
        }

        buffer.frameLength = frameCount
        var scale = Float(1) / 32768
        bytes.withUnsafeBytes { raw in
            let samples = raw.bindMemory(to: Int16.self).baseAddress!
            for channel in 0..<Int(Self.channels) {
                vDSP_vflt16(samples + channel, 2, channels[channel], 1, vDSP_Length(frameCount))
                vDSP_vsmul(channels[channel], 1, &scale, channels[channel], 1, vDSP_Length(frameCount))
            }
        }

        node.scheduleBuffer(buffer) { [weak self] in
            self?.release(frameCount)
        }
    }

    func stop() {
        node.stop()
        engine.stop()
    }

    private func reserve(_ frames: AVAudioFrameCount) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard queuedFrames <= Self.maxQueuedFrames else { return false }
        queuedFrames += AVAudioFramePosition(frames)
        return true
    }

    private func release(_ frames: AVAudioFrameCount) {
        lock.lock()
        queuedFrames -= AVAudioFramePosition(frames)
        lock.unlock()
    }
}
