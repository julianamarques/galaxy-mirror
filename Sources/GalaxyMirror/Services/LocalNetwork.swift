import Darwin
import Foundation

enum LocalNetwork {
    struct Interface: Equatable {
        let name: String
        let address: String
        let netmask: String
    }

    static func interfaces() -> [Interface] {
        var head: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&head) == 0, let first = head else { return [] }
        defer { freeifaddrs(head) }

        return sequence(first: first, next: { $0.pointee.ifa_next })
            .compactMap { pointer -> Interface? in
                let entry = pointer.pointee
                let flags = Int32(entry.ifa_flags)
                guard let address = entry.ifa_addr, let netmask = entry.ifa_netmask,
                      address.pointee.sa_family == UInt8(AF_INET),
                      flags & IFF_UP != 0, flags & IFF_LOOPBACK == 0
                else { return nil }
                return Interface(
                    name: String(cString: entry.ifa_name),
                    address: numericHost(address),
                    netmask: numericHost(netmask)
                )
            }
            .sorted { $0.name.hasPrefix("en") && !$1.name.hasPrefix("en") }
    }

    static func ipv4(_ string: String) -> UInt32? {
        var address = in_addr()
        guard inet_pton(AF_INET, string, &address) == 1 else { return nil }
        return UInt32(bigEndian: address.s_addr)
    }

    static func isInSubnet(_ host: String, of interface: Interface) -> Bool {
        guard let host = ipv4(host), let address = ipv4(interface.address), let mask = ipv4(interface.netmask) else {
            return false
        }
        return host & mask == address & mask
    }

    static func gateway(fromRouteOutput output: String) -> String? {
        output
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first { $0.hasPrefix("gateway:") }
            .map { $0.dropFirst("gateway:".count).trimmingCharacters(in: .whitespaces) }
    }

    static func defaultGateway() async -> String? {
        guard let result = try? await Tools.run(URL(fileURLWithPath: "/sbin/route"), ["-n", "get", "default"], timeout: 5) else {
            return nil
        }
        return gateway(fromRouteOutput: result.stdout)
    }

    static func diagnose(phoneHost: String) async -> ToolError? {
        guard ipv4(phoneHost) != nil else { return nil }
        if await defaultGateway() == phoneHost { return .phoneHotspot }

        let interfaces = interfaces()
        guard !interfaces.isEmpty, !interfaces.contains(where: { isInSubnet(phoneHost, of: $0) }) else { return nil }
        return .differentNetwork(mac: interfaces.first?.address, phone: phoneHost)
    }

    private static func numericHost(_ address: UnsafeMutablePointer<sockaddr>) -> String {
        var buffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        getnameinfo(address, socklen_t(address.pointee.sa_len), &buffer, socklen_t(buffer.count), nil, 0, NI_NUMERICHOST)
        return String(decoding: buffer.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }, as: UTF8.self)
    }
}
