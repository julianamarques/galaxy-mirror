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

    @Test func parsesPushAndForwardOutput() {
        #expect(ADBOutputParser.isPushed("scrcpy-server: 1 file pushed, 0 skipped. 30.0 MB/s (733974 bytes in 0.023s)"))
        #expect(!ADBOutputParser.isPushed("adb: error: failed to copy"))
        #expect(ADBOutputParser.forwardedPort("53214\n") == 53214)
        #expect(ADBOutputParser.forwardedPort("error: cannot bind listener") == nil)
    }

    @Test func parsesTrackDevicesStream() {
        var buffer = Array("0000".utf8) + Array("0013RQCY701ZFJA\tdevice\n".utf8) + Array("001E".utf8)

        let lists = ADBOutputParser.trackedDeviceLists(consuming: &buffer)

        #expect(lists.count == 2)
        #expect(lists[0].isEmpty)
        #expect(lists[1].map(\.serial) == ["RQCY701ZFJA"])
        #expect(lists[1].map(\.state) == ["device"])
        #expect(buffer == Array("001E".utf8))
    }

    @Test func extractsHost() {
        #expect(ADBOutputParser.host(of: "192.168.0.10:41235") == "192.168.0.10")
        #expect(ADBOutputParser.host(of: "192.168.0.10") == "192.168.0.10")
    }
}
