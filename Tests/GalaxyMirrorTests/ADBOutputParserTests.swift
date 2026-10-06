import Testing
@testable import GalaxyMirror

struct ADBOutputParserTests {
    @Test func parsesDevices() {
        let output = """
        List of devices attached
        192.168.0.10:41235\tdevice
        adb-R5CX123-AbCdEf._adb-tls-connect._tcp\toffline

        """

        let devices = ADBOutputParser.devices(output)

        #expect(devices.map(\.serial) == ["192.168.0.10:41235", "adb-R5CX123-AbCdEf._adb-tls-connect._tcp"])
        #expect(devices.map(\.state) == ["device", "offline"])
    }

    @Test func parsesSuccessfulPairing() {
        let output = "Successfully paired to 192.168.0.10:37123 [guid=adb-R5CX123-AbCdEf]"

        #expect(ADBOutputParser.isPaired(output))
        #expect(ADBOutputParser.pairingGUID(output) == "adb-R5CX123-AbCdEf")
    }

    @Test func detectsFailedPairing() {
        let output = "error: protocol fault (couldn't read status message): Undefined error: 0"

        #expect(!ADBOutputParser.isPaired(output))
        #expect(ADBOutputParser.pairingGUID(output) == nil)
    }

    @Test func detectsNetworkAddress() {
        #expect(ADBOutputParser.networkAddress("192.168.0.10:41235") == "192.168.0.10:41235")
        #expect(ADBOutputParser.networkAddress("adb-R5CX123-AbCdEf._adb-tls-connect._tcp") == nil)
    }

    @Test func distinguishesUSBFromWirelessSerials() {
        #expect(ADBOutputParser.isUSBSerial("R5CX123ABC"))
        #expect(!ADBOutputParser.isUSBSerial("192.168.0.10:41235"))
        #expect(!ADBOutputParser.isUSBSerial("adb-R5CX123-AbCdEf._adb-tls-connect._tcp"))
    }

    @Test func extractsHost() {
        #expect(ADBOutputParser.host(of: "192.168.0.10:41235") == "192.168.0.10")
        #expect(ADBOutputParser.host(of: "192.168.0.10") == "192.168.0.10")
    }
}
