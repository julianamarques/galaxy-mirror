import Foundation

struct MDNSService: Equatable, Identifiable {
    static let pairingType = "_adb-tls-pairing._tcp"
    static let connectType = "_adb-tls-connect._tcp"

    let name: String
    let type: String
    let address: String

    var id: String { name + type }
    var host: String { ADBOutputParser.host(of: address) }
}
