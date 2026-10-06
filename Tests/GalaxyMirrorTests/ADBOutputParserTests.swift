import Testing
@testable import GalaxyMirror

struct ADBOutputParserTests {
    @Test func parsesMDNSServices() {
        let output = """
        List of discovered mdns services
        adb-R5CX123-AbCdEf\t_adb-tls-connect._tcp\t192.168.0.10:41235
        studio-abc123\t_adb-tls-pairing._tcp\t192.168.0.10:37123
        """

        let services = ADBOutputParser.mdnsServices(output)

        #expect(services.count == 2)
        #expect(services[0] == MDNSService(name: "adb-R5CX123-AbCdEf", type: "_adb-tls-connect._tcp", address: "192.168.0.10:41235"))
        #expect(services[0].isConnect)
        #expect(services[1].isPairing)
        #expect(services[1].host == "192.168.0.10")
    }

    @Test func ignoresEmptyMDNSList() {
        #expect(ADBOutputParser.mdnsServices("List of discovered mdns services\n").isEmpty)
    }

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

    @Test func extractsHost() {
        #expect(ADBOutputParser.host(of: "192.168.0.10:41235") == "192.168.0.10")
        #expect(ADBOutputParser.host(of: "192.168.0.10") == "192.168.0.10")
    }
}
