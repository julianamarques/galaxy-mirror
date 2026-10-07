import Foundation

struct PairedDevice: Codable {
    var guid: String?
    var name: String
    var lastAddress: String?
    var usbSerial: String?

    var supportsWiFi: Bool { guid != nil || lastAddress != nil }

    func matchesUSB(_ serial: String) -> Bool {
        usbSerial == serial || guid?.hasPrefix("adb-\(serial)-") == true
    }

    func matches(_ serial: String) -> Bool {
        if ADBOutputParser.isUSBSerial(serial) { return matchesUSB(serial) }
        if let guid, serial.hasPrefix(guid) { return true }
        guard let lastAddress else { return false }
        return serial.hasPrefix(ADBOutputParser.host(of: lastAddress) + ":")
    }
}
