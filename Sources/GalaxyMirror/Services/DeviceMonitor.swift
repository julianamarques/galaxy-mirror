import Foundation

final class DeviceMonitor: @unchecked Sendable {
    private let lock = NSLock()
    private var process: Process?
    private var isRunning = false

    func start(onChange: @escaping @Sendable ([ADBDevice]) -> Void) {
        lock.lock()
        isRunning = true
        lock.unlock()
        launch(onChange: onChange)
    }

    func stop() {
        lock.lock()
        isRunning = false
        let process = process
        lock.unlock()
        process?.terminate()
    }

    private func launch(onChange: @escaping @Sendable ([ADBDevice]) -> Void) {
        guard let adb = Tools.find("adb") else { return }
        let process = Tools.makeProcess(adb, ["track-devices"])
        let output = Pipe()
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice

        let buffer = ByteBuffer()
        output.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else {
                handle.readabilityHandler = nil
                return
            }
            buffer.append(data).forEach(onChange)
        }
        process.terminationHandler = { [weak self] _ in
            self?.relaunch(onChange: onChange)
        }

        lock.lock()
        self.process = process
        lock.unlock()
        try? process.run()
    }

    private func relaunch(onChange: @escaping @Sendable ([ADBDevice]) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
            guard self.isMonitoring else { return }
            self.launch(onChange: onChange)
        }
    }

    private var isMonitoring: Bool {
        lock.lock()
        defer { lock.unlock() }
        return isRunning
    }

    private final class ByteBuffer: @unchecked Sendable {
        private let lock = NSLock()
        private var bytes: [UInt8] = []

        func append(_ data: Data) -> [[ADBDevice]] {
            lock.lock()
            defer { lock.unlock() }
            bytes.append(contentsOf: data)
            return ADBOutputParser.trackedDeviceLists(consuming: &bytes)
        }
    }
}
