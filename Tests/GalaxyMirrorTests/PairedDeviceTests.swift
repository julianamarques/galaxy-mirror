import Foundation
import Testing
@testable import GalaxyMirror

struct PairedDeviceTests {
    @Test func matchesUSBSerialFromWirelessGUID() {
        let device = PairedDevice(guid: "adb-R5CX123ABC-vWgJpq", name: "S25", lastAddress: nil, usbSerial: nil)

        #expect(device.matchesUSB("R5CX123ABC"))
        #expect(!device.matchesUSB("R5CX999ZZZ"))
        #expect(device.supportsWiFi)
    }

    @Test func matchesStoredUSBSerial() {
        let device = PairedDevice(guid: nil, name: "S25", lastAddress: nil, usbSerial: "R5CX123ABC")

        #expect(device.matchesUSB("R5CX123ABC"))
        #expect(!device.supportsWiFi)
    }

    @Test func decodesDevicesSavedBeforeUSBSupport() throws {
        let json = #"{"guid":"adb-R5CX123ABC-vWgJpq","name":"S25","lastAddress":"192.168.18.48:44401"}"#

        let device = try JSONDecoder().decode(PairedDevice.self, from: Data(json.utf8))

        #expect(device.usbSerial == nil)
        #expect(device.lastAddress == "192.168.18.48:44401")
    }
}
