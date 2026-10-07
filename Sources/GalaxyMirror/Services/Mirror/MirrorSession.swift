import AppKit
import AVFoundation

@MainActor
final class MirrorSession {
    private enum Event: Sendable {
        case videoSize(CGSize)
        case firstFrame
        case clipboard(String)
        case ended(String)
    }

    let displayLayer = AVSampleBufferDisplayLayer()
    private(set) var videoSize: CGSize = .zero
    var onVideoSizeChange: ((CGSize) -> Void)?

    private let connection: ServerConnection
    private let controlQueue = DispatchQueue(label: "GalaxyMirror.control")
    private var audioPlayer: AudioPlayer?
    private var hasFrame = false
    private var endMessage: String?
    private var isStopped = false
    private var firstFrameWaiter: CheckedContinuation<Void, Error>?
    private var endWaiter: CheckedContinuation<String?, Never>?
    private var lastClipboard: String?
    private var clipboardSequence: UInt64 = 0

    init(connection: ServerConnection) {
        self.connection = connection
        displayLayer.videoGravity = .resizeAspect
        displayLayer.backgroundColor = NSColor.black.cgColor
    }

    func start() {
        let deliver: @Sendable (Event) -> Void = { [weak self] event in
            DispatchQueue.main.async {
                MainActor.assumeIsolated { self?.handle(event) }
            }
        }
        let control = connection.control
        let controlQueue = controlQueue
        let renderer = VideoRenderer(renderer: displayLayer.sampleBufferRenderer) {
            controlQueue.async { try? control.write(ControlMessage.resetVideo.data) }
        }

        let video = connection.video
        Thread.detachNewThread { Self.readVideo(from: video, renderer: renderer, deliver: deliver) }

        if let audio = connection.audio {
            let player = AudioPlayer()
            if (try? player.start()) != nil {
                audioPlayer = player
                Thread.detachNewThread { try? Self.readAudio(from: audio, player: player) }
            }
        }

        Thread.detachNewThread { Self.readDeviceMessages(from: control, deliver: deliver) }
    }

    func waitForFirstFrame(timeout: TimeInterval) async throws {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                if hasFrame { return continuation.resume() }
                if let endMessage { return continuation.resume(throwing: ToolError.failed(endMessage)) }
                if isStopped { return continuation.resume(throwing: CancellationError()) }
                firstFrameWaiter = continuation
                DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { [weak self] in
                    MainActor.assumeIsolated { self?.resumeFirstFrameWaiter(throwing: ToolError.mirrorTimeout) }
                }
            }
        } onCancel: {
            Task { @MainActor in self.stop() }
        }
    }

    func waitUntilEnded() async -> String? {
        await withTaskCancellationHandler {
            await withCheckedContinuation { (continuation: CheckedContinuation<String?, Never>) in
                if isStopped { return continuation.resume(returning: endMessage) }
                endWaiter = continuation
            }
        } onCancel: {
            Task { @MainActor in self.stop() }
        }
    }

    func send(_ message: ControlMessage) {
        guard !isStopped else { return }
        let control = connection.control
        let data = message.data
        controlQueue.async { try? control.write(data) }
    }

    func sendKey(_ keycode: AndroidKeycode) {
        send(.keycode(action: .down, keycode: keycode.rawValue))
        send(.keycode(action: .up, keycode: keycode.rawValue))
    }

    func paste(_ text: String) {
        clipboardSequence += 1
        lastClipboard = text
        send(.setClipboard(sequence: clipboardSequence, text: text, paste: true))
    }

    func stop() {
        guard !isStopped else { return }
        isStopped = true
        audioPlayer?.stop()
        connection.close()
        displayLayer.flushAndRemoveImage()
        resumeFirstFrameWaiter(throwing: endMessage.map { ToolError.failed($0) } ?? CancellationError())
        endWaiter?.resume(returning: endMessage)
        endWaiter = nil
    }

    private func resumeFirstFrameWaiter(throwing error: Error) {
        firstFrameWaiter?.resume(throwing: error)
        firstFrameWaiter = nil
    }

    private func handle(_ event: Event) {
        guard !isStopped else { return }
        switch event {
        case .videoSize(let size):
            videoSize = size
            onVideoSizeChange?(size)
        case .firstFrame:
            hasFrame = true
            firstFrameWaiter?.resume()
            firstFrameWaiter = nil
        case .clipboard(let text):
            guard text != lastClipboard else { return }
            lastClipboard = text
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
        case .ended(let message):
            endMessage = connection.log.lastError ?? message
            stop()
        }
    }

    private nonisolated static func readVideo(from socket: TCPSocket, renderer: VideoRenderer, deliver: @Sendable (Event) -> Void) {
        do {
            guard let codec = Codec(scrcpyID: try socket.read(exactly: 4).bigEndian(at: 0)) else {
                throw ToolError.failed("O Galaxy não conseguiu iniciar o vídeo.")
            }
            let builder = VideoSampleBuilder(codec: codec)

            while true {
                guard let header = ScrcpyProtocol.parseHeader(try socket.read(exactly: ScrcpyProtocol.headerLength)) else {
                    throw ToolError.failed("Dados de vídeo inválidos.")
                }
                switch header {
                case let .session(width, height):
                    renderer.flush()
                    deliver(.videoSize(CGSize(width: width, height: height)))
                case let .media(isConfig, isKeyFrame, pts, size):
                    let payload = try socket.read(exactly: size)
                    if isConfig {
                        try builder.applyConfig(payload)
                    } else if let sample = try builder.sampleBuffer(payload, pts: pts, isKeyFrame: isKeyFrame),
                              renderer.enqueue(sample, isKeyFrame: isKeyFrame) {
                        deliver(.firstFrame)
                    }
                }
            }
        } catch {
            deliver(.ended(error.localizedDescription))
        }
    }

    private nonisolated static func readAudio(from socket: TCPSocket, player: AudioPlayer) throws {
        guard try socket.read(exactly: 4).bigEndian(at: 0, as: UInt32.self) == ScrcpyProtocol.rawAudioCodecID else { return }
        while case let .media(isConfig, _, _, size)? = ScrcpyProtocol.parseHeader(try socket.read(exactly: ScrcpyProtocol.headerLength)) {
            let payload = try socket.read(exactly: size)
            if !isConfig { player.play(interleavedInt16: payload) }
        }
    }

    private nonisolated static func readDeviceMessages(from socket: TCPSocket, deliver: @Sendable (Event) -> Void) {
        while let message = try? DeviceMessage.read(using: socket.read(exactly:)) {
            if case .clipboard(let text) = message {
                deliver(.clipboard(text))
            }
        }
    }
}
