import Foundation

struct ADBDevice {
    let serial: String
    let state: String

    var isReady: Bool { state == "device" }
    var isUSB: Bool { ADBOutputParser.isUSBSerial(serial) }
}
