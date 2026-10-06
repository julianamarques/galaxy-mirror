import Darwin
import dnssd
import Foundation

enum Bonjour {
    static func services(ofType type: String, browseTime: TimeInterval = 3) async -> [MDNSService] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let services = browse(type, duration: browseTime).compactMap { name -> MDNSService? in
                    guard let target = resolve(name, type), let ip = ipv4Address(of: target.host) else { return nil }
                    return MDNSService(name: name, type: type, address: "\(ip):\(target.port)")
                }
                continuation.resume(returning: services)
            }
        }
    }

    private final class BrowseResult {
        var names: [String] = []
        var isComplete = false
    }

    private final class ResolveResult {
        var host: String?
        var port: UInt16 = 0
    }

    private static func browse(_ type: String, duration: TimeInterval) -> [String] {
        let result = BrowseResult()
        var reference: DNSServiceRef?
        let status = DNSServiceBrowse(
            &reference, 0, 0, type, "local.",
            { _, flags, _, error, name, _, _, context in
                guard error == kDNSServiceErr_NoError, let name, let context else { return }
                let result = Unmanaged<BrowseResult>.fromOpaque(context).takeUnretainedValue()
                let value = String(cString: name)
                if flags & DNSServiceFlags(kDNSServiceFlagsAdd) != 0 {
                    if !result.names.contains(value) { result.names.append(value) }
                } else {
                    result.names.removeAll { $0 == value }
                }
                result.isComplete = flags & DNSServiceFlags(kDNSServiceFlagsMoreComing) == 0 && !result.names.isEmpty
            },
            Unmanaged.passUnretained(result).toOpaque()
        )
        guard status == kDNSServiceErr_NoError, let reference else { return [] }
        defer { DNSServiceRefDeallocate(reference) }

        process(reference, until: Date().addingTimeInterval(duration)) { result.isComplete }
        return result.names
    }

    private static func resolve(_ name: String, _ type: String) -> (host: String, port: UInt16)? {
        let result = ResolveResult()
        var reference: DNSServiceRef?
        let status = DNSServiceResolve(
            &reference, 0, 0, name, type, "local.",
            { _, _, _, error, _, host, port, _, _, context in
                guard error == kDNSServiceErr_NoError, let host, let context else { return }
                let result = Unmanaged<ResolveResult>.fromOpaque(context).takeUnretainedValue()
                result.host = String(cString: host)
                result.port = UInt16(bigEndian: port)
            },
            Unmanaged.passUnretained(result).toOpaque()
        )
        guard status == kDNSServiceErr_NoError, let reference else { return nil }
        defer { DNSServiceRefDeallocate(reference) }

        process(reference, until: Date().addingTimeInterval(2)) { result.host != nil }
        return result.host.map { ($0, result.port) }
    }

    private static func process(_ reference: DNSServiceRef, until deadline: Date, isDone: () -> Bool) {
        var descriptor = pollfd(fd: DNSServiceRefSockFD(reference), events: Int16(POLLIN), revents: 0)
        while !isDone() {
            let remaining = Int32(deadline.timeIntervalSinceNow * 1000)
            guard remaining > 0, poll(&descriptor, 1, remaining) > 0,
                  DNSServiceProcessResult(reference) == kDNSServiceErr_NoError
            else { return }
        }
    }

    private static func ipv4Address(of host: String) -> String? {
        var hints = addrinfo()
        hints.ai_family = AF_INET
        hints.ai_socktype = SOCK_STREAM
        var info: UnsafeMutablePointer<addrinfo>?
        guard getaddrinfo(host, nil, &hints, &info) == 0, let first = info, let address = first.pointee.ai_addr else {
            return nil
        }
        defer { freeaddrinfo(info) }

        var buffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        guard getnameinfo(address, first.pointee.ai_addrlen, &buffer, socklen_t(buffer.count), nil, 0, NI_NUMERICHOST) == 0 else {
            return nil
        }
        return String(decoding: buffer.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }, as: UTF8.self)
    }
}
