import Testing
@testable import GalaxyMirror

struct ConnectionProblemTests {
    @Test func explainsPhoneHotspot() {
        let problem = ConnectionProblem(ToolError.phoneHotspot)

        #expect(problem.title == "O Mac está usando o hotspot do Galaxy")
        #expect(problem.suggestsUSB)
        #expect(problem.detail == nil)
    }

    @Test func explainsDifferentNetwork() {
        let problem = ConnectionProblem(ToolError.differentNetwork(mac: "10.187.111.5", phone: "192.168.18.48"))

        #expect(problem.message.contains("192.168.18.48"))
        #expect(problem.message.contains("10.187.111.5"))
        #expect(problem.suggestsUSB)
    }

    @Test func offersWiFiSetupWhenUSBIsMissing() {
        let problem = ConnectionProblem(ToolError.usbNotConnected)

        #expect(problem.title == "O Galaxy não está conectado")
        #expect(problem.message.contains("Configurar Wi-Fi"))
    }

    @Test func asksForLocalNetworkPermission() {
        let problem = ConnectionProblem(ToolError.localNetworkDenied)

        #expect(problem.needsLocalNetworkPermission)
        #expect(problem.message.contains("Rede Local"))
        #expect(!ConnectionProblem(ToolError.timeout).needsLocalNetworkPermission)
    }

    @Test func keepsTechnicalDetailForGenericErrors() {
        let problem = ConnectionProblem(ToolError.timeout)

        #expect(problem.title == "Não é possível conectar ao Galaxy")
        #expect(problem.detail == "O Galaxy não respondeu a tempo.")
        #expect(!problem.suggestsUSB)
    }
}
