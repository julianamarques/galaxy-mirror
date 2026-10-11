import Foundation

enum ScrcpyServer {
    static var bundledServer: URL? {
        [
            Bundle.main.resourceURL?.appendingPathComponent("scrcpy-server"),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Resources/scrcpy-server"),
        ]
        .compactMap { $0 }
        .first { FileManager.default.fileExists(atPath: $0.path) }
    }

    static func start(serial: String, options: MirrorOptions) async throws -> ServerConnection {
        guard let server = bundledServer else { throw ToolError.missing("scrcpy-server") }
        let adb = try Tools.require("adb")

        let scid = String(format: "%08x", UInt32.random(in: 0..<0x8000_0000))
        async let pushed: Void = ADB.push(server, to: ScrcpyProtocol.devicePath, serial: serial)
        async let forwardedPort = ADB.forward("localabstract:scrcpy_\(scid)", serial: serial)
        let port: UInt16
        do {
            try await pushed
            port = try await forwardedPort
        } catch {
            if let port = try? await forwardedPort { await ADB.removeForward(port: port, serial: serial) }
            throw error
        }

        let process = Tools.makeProcess(adb, [
            "-s", serial, "shell",
            "CLASSPATH=\(ScrcpyProtocol.devicePath)", "app_process", "/", "com.genymobile.scrcpy.Server",
            ScrcpyProtocol.serverVersion, "scid=\(scid)",
        ] + options.serverArguments)
        let log = ServerLog()
        let output = Pipe()
        process.standardOutput = output
        process.standardError = output
        log.attach(to: output)

        let result: Result<ServerConnection, Error>
        do {
            try process.run()
            result = .success(try await connect(port: port, audio: options.audio, process: process, log: log))
        } catch {
            if process.isRunning { process.terminate() }
            result = .failure(log.lastError.map(ToolError.failed) ?? error)
        }
        await ADB.removeForward(port: port, serial: serial)
        return try result.get()
    }

    private static func connect(port: UInt16, audio: Bool, process: Process, log: ServerLog) async throws -> ServerConnection {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let video = try connectFirstSocket(port: port, process: process)
                    let audioSocket = audio ? try TCPSocket(connectingToLocalPort: port) : nil
                    let control = try TCPSocket(connectingToLocalPort: port)
                    control.disableNagle()
                    video.setReadTimeout(10)
                    _ = try video.read(exactly: ScrcpyProtocol.deviceNameLength)
                    video.setReadTimeout(0)
                    continuation.resume(returning: ServerConnection(
                        video: video, audio: audioSocket, control: control, process: process, log: log
                    ))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private static func connectFirstSocket(port: UInt16, process: Process) throws -> TCPSocket {
        for _ in 0..<100 {
            guard process.isRunning else { throw ToolError.failed(String(localized: "O servidor de espelhamento encerrou no Galaxy.")) }
            if let socket = try? TCPSocket(connectingToLocalPort: port) {
                socket.setReadTimeout(2)
                if (try? socket.read(exactly: 1)) != nil {
                    socket.setReadTimeout(0)
                    return socket
                }
                socket.close()
            }
            Thread.sleep(forTimeInterval: 0.1)
        }
        throw ToolError.failed(String(localized: "O servidor de espelhamento não respondeu."))
    }
}
