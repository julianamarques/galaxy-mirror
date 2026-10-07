import Foundation

final class ServerLog: @unchecked Sendable {
    private let lock = NSLock()
    private var lines: [String] = []
    private var partial = ""

    func attach(to pipe: Pipe) {
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else {
                handle.readabilityHandler = nil
                return
            }
            self?.append(String(decoding: data, as: UTF8.self))
        }
    }

    var lastError: String? {
        lock.lock()
        defer { lock.unlock() }
        let errors = lines.filter { $0.contains("ERROR") || $0.contains("Exception") }.suffix(3)
        return errors.isEmpty ? nil : errors.joined(separator: "\n")
    }

    func append(_ text: String) {
        lock.lock()
        defer { lock.unlock() }
        let pieces = (partial + text).split(separator: "\n", omittingEmptySubsequences: false)
        partial = String(pieces.last ?? "")
        lines.append(contentsOf: pieces.dropLast().map(String.init))
        lines = Array(lines.suffix(50))
    }
}
