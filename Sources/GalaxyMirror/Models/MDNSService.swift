import Foundation

struct MDNSService: Equatable, Identifiable {
    let name: String
    let type: String
    let address: String

    var id: String { name + type }
    var isPairing: Bool { type.hasPrefix("_adb-tls-pairing") }
    var isConnect: Bool { type.hasPrefix("_adb-tls-connect") }
    var host: String { ADBOutputParser.host(of: address) }
}
