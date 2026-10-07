import AVFoundation

final class VideoRenderer: @unchecked Sendable {
    private let renderer: AVSampleBufferVideoRenderer
    private let requestKeyFrame: @Sendable () -> Void
    private let lock = NSLock()
    private var awaitingKeyFrame = false
    private var hasRendered = false

    init(renderer: AVSampleBufferVideoRenderer, requestKeyFrame: @escaping @Sendable () -> Void) {
        self.renderer = renderer
        self.requestKeyFrame = requestKeyFrame
    }

    func enqueue(_ sample: CMSampleBuffer, isKeyFrame: Bool) -> Bool {
        if renderer.status == .failed || renderer.requiresFlushToResumeDecoding {
            renderer.flush()
            awaitKeyFrame()
        }

        lock.lock()
        if awaitingKeyFrame, !isKeyFrame {
            lock.unlock()
            return false
        }
        awaitingKeyFrame = false
        let isFirst = !hasRendered
        hasRendered = true
        lock.unlock()

        renderer.enqueue(sample)
        return isFirst
    }

    func flush() {
        renderer.flush()
    }

    private func awaitKeyFrame() {
        lock.lock()
        let shouldRequest = !awaitingKeyFrame
        awaitingKeyFrame = true
        lock.unlock()
        if shouldRequest { requestKeyFrame() }
    }
}
