import Foundation

enum ADBOutputParser {
    static func host(of address: String) -> String {
        guard let colon = address.lastIndex(of: ":") else { return address }
        return String(address[..<colon])
    }

    static func networkAddress(_ serial: String) -> String? {
        serial.contains(":") ? serial : nil
    }

    static func mdnsServices(_ output: String) -> [MDNSService] {
        output
            .split(separator: "\n")
            .compactMap { line -> MDNSService? in
                var parts = line.split(separator: "\t").map { $0.trimmingCharacters(in: .whitespaces) }
                if parts.count < 3 { parts = line.split(whereSeparator: \.isWhitespace).map(String.init) }
                guard parts.count >= 3, parts[1].hasPrefix("_adb") else { return nil }
                return MDNSService(name: parts[0], type: parts[1], address: parts[2])
            }
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

    static func isPaired(_ output: String) -> Bool {
        output.contains("Successfully paired")
    }

    static func pairingGUID(_ output: String) -> String? {
        guard let range = output.range(of: #"guid=([^\]\s]+)"#, options: .regularExpression) else { return nil }
        return String(output[range].dropFirst("guid=".count))
    }
}
