import Foundation

enum ADBOutputParser {
    static func host(of address: String) -> String {
        guard let colon = address.lastIndex(of: ":") else { return address }
        return String(address[..<colon])
    }

    static func networkAddress(_ serial: String) -> String? {
        serial.contains(":") ? serial : nil
    }

    static func isUSBSerial(_ serial: String) -> Bool {
        !serial.contains(":") && !serial.contains("._adb-tls")
    }

    static func devices(_ output: String) -> [ADBDevice] {
        output
            .split(separator: "\n")
            .dropFirst()
            .compactMap { line in
                let parts = line.split(whereSeparator: \.isWhitespace).map(String.init)
                guard parts.count >= 2 else { return nil }
                return ADBDevice(serial: parts[0], state: parts[1])
            }
    }

    static func isPushed(_ output: String) -> Bool {
        output.contains("pushed")
    }

    static func forwardedPort(_ output: String) -> UInt16? {
        UInt16(output.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    static func isPaired(_ output: String) -> Bool {
        output.contains("Successfully paired")
    }

    static func pairingGUID(_ output: String) -> String? {
        guard let range = output.range(of: #"guid=([^\]\s]+)"#, options: .regularExpression) else { return nil }
        return String(output[range].dropFirst("guid=".count))
    }
}
