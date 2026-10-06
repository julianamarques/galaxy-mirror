import Testing
@testable import GalaxyMirror

struct LocalNetworkTests {
    private let wifi = LocalNetwork.Interface(name: "en0", address: "10.187.111.5", netmask: "255.255.255.0")

    @Test func detectsHostInSameSubnet() {
        #expect(LocalNetwork.isInSubnet("10.187.111.195", of: wifi))
    }

    @Test func detectsHostInOtherSubnet() {
        #expect(!LocalNetwork.isInSubnet("192.168.18.48", of: wifi))
    }

    @Test func rejectsInvalidAddresses() {
        #expect(LocalNetwork.ipv4("galaxy.local") == nil)
        #expect(!LocalNetwork.isInSubnet("galaxy.local", of: wifi))
    }

    @Test func parsesDefaultGateway() {
        let output = """
           route to: default
        destination: default
               mask: default
            gateway: 10.187.111.195
          interface: en0
        """

        #expect(LocalNetwork.gateway(fromRouteOutput: output) == "10.187.111.195")
        #expect(LocalNetwork.gateway(fromRouteOutput: "route: writing to routing socket: not in table") == nil)
    }
}
