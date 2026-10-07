import Foundation

enum ADB {
    static func run(_ arguments: [String], timeout: TimeInterval, captureOutput: Bool = true) async throws -> CommandResult {
        let start = Date()
        do {
            let result = try await Tools.run(Tools.require("adb"), arguments, timeout: timeout, captureOutput: captureOutput)
            let elapsed = Date().timeIntervalSince(start)
            Log.adb.debug("adb \(arguments.joined(separator: " "), privacy: .public) → \(elapsed, format: .fixed(precision: 2))s \(result.output.prefix(200), privacy: .public)")
            return result
        } catch {
            Log.adb.error("adb \(arguments.joined(separator: " "), privacy: .public) falhou: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    static func startServer() async {
        _ = try? await run(["start-server"], timeout: 15, captureOutput: false)
    }

    static func devices() async -> [ADBDevice] {
        guard let result = try? await run(["devices"], timeout: 10) else { return [] }
        return ADBOutputParser.devices(result.stdout)
    }

    static func isReady(_ serial: String) async -> Bool {
        await devices().contains { $0.serial == serial && $0.isReady }
    }

    static func pair(address: String, code: String) async throws -> String? {
        let result = try await run(["pair", address, code], timeout: 30)
        guard ADBOutputParser.isPaired(result.output) else {
            let message = ["O pareamento foi recusado. Confira o código e tente novamente.", result.output]
                .filter { !$0.isEmpty }
                .joined(separator: "\n")
            throw ToolError.failed(message)
        }
        return ADBOutputParser.pairingGUID(result.output)
    }

    static func push(_ file: URL, to path: String, serial: String) async throws {
        let result = try await run(["-s", serial, "push", file.path, path], timeout: 30)
        guard ADBOutputParser.isPushed(result.output) else {
            throw ToolError.failed(["Não foi possível enviar o servidor de espelhamento ao Galaxy.", result.output].joined(separator: "\n"))
        }
    }

    static func forward(_ remote: String, serial: String) async throws -> UInt16 {
        let result = try await run(["-s", serial, "forward", "tcp:0", remote], timeout: 10)
        guard let port = ADBOutputParser.forwardedPort(result.stdout) else {
            throw ToolError.failed(["Não foi possível abrir o túnel com o Galaxy.", result.output].joined(separator: "\n"))
        }
        return port
    }

    static func removeForward(port: UInt16, serial: String) async {
        _ = try? await run(["-s", serial, "forward", "--remove", "tcp:\(port)"], timeout: 5)
    }

    static func enableWirelessDebugging(serial: String) async {
        _ = try? await run(["-s", serial, "shell", "settings", "put", "global", "adb_wifi_enabled", "1"], timeout: 5)
    }

    static func connect(address: String) async {
        _ = try? await run(["connect", address], timeout: 12)
    }

    static func disconnect(_ serial: String) async {
        _ = try? await run(["disconnect", serial], timeout: 5)
    }

    static func waitForConnection(
        guid: String?,
        host: String? = nil,
        lastAddress: String? = nil,
        acceptsUSB: (String) -> Bool = { _ in false },
        timeout: TimeInterval = 20
    ) async throws -> String {
        let host = host ?? lastAddress.map(ADBOutputParser.host(of:))

        func matches(_ serial: String) -> Bool {
            if ADBOutputParser.isUSBSerial(serial) { return acceptsUSB(serial) }
            if let guid, serial.hasPrefix(guid) { return true }
            if let host, serial.hasPrefix(host + ":") { return true }
            return false
        }

        let deadline = Date().addingTimeInterval(timeout)
        var triedLastAddress = false

        while Date() < deadline {
            try Task.checkCancellation()

            if let ready = await devices().first(where: { $0.isReady && matches($0.serial) }) {
                return ready.serial
            }

            let service = guid == nil && host == nil ? nil : await Bonjour.services(ofType: MDNSService.connectType).first { service in
                if let guid { return service.name == guid }
                return service.host == host
            }

            var candidate = service?.address
            if candidate == nil, !triedLastAddress {
                candidate = lastAddress
                triedLastAddress = true
            }
            if let candidate {
                await connect(address: candidate)
                if await isReady(candidate) { return candidate }
            }

            try await Task.sleep(for: .seconds(1))
        }

        if let host, let problem = await LocalNetwork.diagnose(phoneHost: host) {
            throw problem
        }
        throw ToolError.timeout
    }

    static func usbDevices() async -> [ADBDevice] {
        await devices().filter(\.isUSB)
    }

    static func deviceName(_ serial: String) async -> String {
        for command in [["settings", "get", "global", "device_name"], ["getprop", "ro.product.model"]] {
            if let result = try? await run(["-s", serial, "shell"] + command, timeout: 8) {
                let name = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
                if !name.isEmpty, name != "null" { return name }
            }
        }
        return "Galaxy"
    }
}
