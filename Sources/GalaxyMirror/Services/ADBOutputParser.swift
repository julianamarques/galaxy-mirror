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
        deviceLines(output.split(separator: "\n").dropFirst())
    }

    private static func deviceLines<Lines: Sequence>(_ lines: Lines) -> [ADBDevice] where Lines.Element == Substring {
        lines.compactMap { line in
            let parts = line.split(whereSeparator: \.isWhitespace).map(String.init)
            guard parts.count >= 2 else { return nil }
            return ADBDevice(serial: parts[0], state: parts[1])
        }
    }

    static func trackedDeviceLists(consuming buffer: inout [UInt8]) -> [[ADBDevice]] {
        var lists: [[ADBDevice]] = []
        while buffer.count >= 4,
              let length = Int(String(decoding: buffer[0..<4], as: UTF8.self), radix: 16),
              buffer.count >= 4 + length {
            let payload = String(decoding: buffer[4..<4 + length], as: UTF8.self)
            lists.append(deviceLines(payload.split(separator: "\n")))
            buffer.removeFirst(4 + length)
        }
        return lists
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
