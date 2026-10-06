import Foundation

enum ADB {
    static func run(_ arguments: [String], timeout: TimeInterval, captureOutput: Bool = true) async throws -> CommandResult {
        try await Tools.run(Tools.require("adb"), arguments, timeout: timeout, captureOutput: captureOutput)
    }

    static func startServer() async {
        _ = try? await run(["start-server"], timeout: 15, captureOutput: false)
    }

    static func mdnsServices() async -> [MDNSService] {
        guard let result = try? await run(["mdns", "services"], timeout: 10) else { return [] }
        return ADBOutputParser.mdnsServices(result.stdout)
    }

    static func devices() async -> [ADBDevice] {
        guard let result = try? await run(["devices"], timeout: 10) else { return [] }
        return ADBOutputParser.devices(result.stdout)
    }

    static func isReady(_ serial: String) async -> Bool {
        await devices().contains { $0.serial == serial && $0.state == "device" }
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

    static func connect(address: String) async {
        _ = try? await run(["connect", address], timeout: 12)
    }

    static func disconnect(_ serial: String) async {
        _ = try? await run(["disconnect", serial], timeout: 5)
    }

    static func waitForConnection(guid: String?, host: String? = nil, lastAddress: String? = nil) async throws -> String {
        let host = host ?? lastAddress.map(ADBOutputParser.host(of:))

        func matches(_ serial: String) -> Bool {
            if let guid, serial.hasPrefix(guid) { return true }
            if let host, serial.hasPrefix(host + ":") { return true }
            return guid == nil && host == nil
        }

        let deadline = Date().addingTimeInterval(20)
        var triedLastAddress = false

        while Date() < deadline {
            try Task.checkCancellation()

            if let ready = await devices().first(where: { $0.state == "device" && matches($0.serial) }) {
                return ready.serial
            }

            let service = await mdnsServices().first { service in
                guard service.isConnect else { return false }
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
        throw ToolError.timeout
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
