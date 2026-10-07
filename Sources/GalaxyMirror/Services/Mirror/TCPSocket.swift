import Darwin
import Foundation

final class TCPSocket: @unchecked Sendable {
    enum SocketError: LocalizedError {
        case connectFailed(Int32)
        case closed

        var errorDescription: String? {
            switch self {
            case .connectFailed(let code): "Falha ao conectar ao Galaxy (\(String(cString: strerror(code))))."
            case .closed: "A conexão com o Galaxy foi encerrada."
            }
        }
    }

    private let descriptor: Int32
    private let lock = NSLock()
    private var isClosed = false

    init(connectingToLocalPort port: UInt16) throws {
        descriptor = socket(AF_INET, SOCK_STREAM, 0)
        guard descriptor >= 0 else { throw SocketError.connectFailed(errno) }

        var enabled: Int32 = 1
        setsockopt(descriptor, SOL_SOCKET, SO_NOSIGPIPE, &enabled, socklen_t(MemoryLayout<Int32>.size))

        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = port.bigEndian
        address.sin_addr.s_addr = inet_addr("127.0.0.1")

        let result = withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                connect(descriptor, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard result == 0 else {
            let code = errno
            Darwin.close(descriptor)
            throw SocketError.connectFailed(code)
        }
    }

    func setReadTimeout(_ seconds: TimeInterval) {
        var timeout = timeval(tv_sec: Int(seconds), tv_usec: Int32((seconds - floor(seconds)) * 1_000_000))
        setsockopt(descriptor, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
    }

    func disableNagle() {
        var enabled: Int32 = 1
        setsockopt(descriptor, IPPROTO_TCP, TCP_NODELAY, &enabled, socklen_t(MemoryLayout<Int32>.size))
    }

    func read(exactly count: Int) throws -> [UInt8] {
        try [UInt8](unsafeUninitializedCapacity: count) { buffer, initialized in
            var received = 0
            while received < count {
                let result = recv(descriptor, buffer.baseAddress! + received, count - received, 0)
                if result > 0 {
                    received += result
                } else if result < 0, errno == EINTR {
                    continue
                } else {
                    throw SocketError.closed
                }
            }
            initialized = count
        }
    }

    func write(_ data: Data) throws {
        try data.withUnsafeBytes { bytes in
            var sent = 0
            while sent < bytes.count {
                let result = send(descriptor, bytes.baseAddress! + sent, bytes.count - sent, 0)
                if result > 0 {
                    sent += result
                } else if result < 0, errno == EINTR {
                    continue
                } else {
                    throw SocketError.closed
                }
            }
        }
    }

    func close() {
        lock.lock()
        defer { lock.unlock() }
        guard !isClosed else { return }
        isClosed = true
        shutdown(descriptor, SHUT_RDWR)
        Darwin.close(descriptor)
    }

    deinit {
        close()
    }
}
