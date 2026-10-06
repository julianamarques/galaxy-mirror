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
}
