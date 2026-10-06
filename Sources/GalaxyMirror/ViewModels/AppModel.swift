import AppKit

@MainActor
final class AppModel: ObservableObject {
    enum Connection: Equatable {
        case idle
        case connecting
        case connected(serial: String)
        case failed(ConnectionProblem)
    }

    @Published private(set) var pairedDevice: PairedDevice?
    @Published var showingSetup: Bool
    @Published private(set) var connection: Connection = .idle
    enum MirrorState { case idle, starting, running }

    @Published private(set) var mirrorState: MirrorState = .idle
    @Published private(set) var mirrorError: String?

    lazy var setup = SetupModel(app: self)

    private var mirrorProcess: Process?
    private var startupTask: Task<Void, Never>?
    private var stoppedByUser = false
    private var startupTimedOut = false
    private var startAttempt = 0
    private static let maxStartRetries = 2
    private static let deviceKey = "pairedDevice"

    init() {
        SettingsKey.register()
        let device = UserDefaults.standard.data(forKey: Self.deviceKey)
            .flatMap { try? JSONDecoder().decode(PairedDevice.self, from: $0) }
        pairedDevice = device
        showingSetup = device == nil
    }

    var deviceName: String { pairedDevice?.name ?? "Galaxy" }
    var isMirroring: Bool { mirrorState != .idle }

    func launched() {
        Task {
            await ADB.startServer()
            guard pairedDevice != nil, !showingSetup else { return }
            if UserDefaults.standard.bool(forKey: SettingsKey.autoStart) {
                await startMirroring()
            } else {
                await ensureConnected()
            }
        }
    }

    func didPair(_ device: PairedDevice, serial: String) {
        save(device)
        connection = .connected(serial: serial)
    }

    func finishSetup(startMirroring start: Bool) {
        showingSetup = false
        if start { Task { await startMirroring() } }
    }

    func forget() {
        stopMirroring()
        if case .connected(let serial) = connection {
            Task { await ADB.disconnect(serial) }
        }
        UserDefaults.standard.removeObject(forKey: Self.deviceKey)
        pairedDevice = nil
        connection = .idle
        setup.reset()
        showingSetup = true
    }

    @discardableResult
    func ensureConnected() async -> String? {
        guard var device = pairedDevice else { return nil }

        if let usb = await ADB.usbDevices().first(where: { $0.isReady && device.matchesUSB($0.serial) }) {
            if device.usbSerial != usb.serial {
                device.usbSerial = usb.serial
                save(device)
            }
            connection = .connected(serial: usb.serial)
            return usb.serial
        }
        if case .connected(let serial) = connection, await ADB.isReady(serial) {
            return serial
        }
        connection = .connecting
        guard device.supportsWiFi else {
            connection = .failed(ConnectionProblem(ToolError.usbNotConnected))
            return nil
        }

        do {
            let serial = try await ADB.waitForConnection(guid: device.guid, lastAddress: device.lastAddress)
            if let address = ADBOutputParser.networkAddress(serial) {
                device.lastAddress = address
                save(device)
            }
            connection = .connected(serial: serial)
            return serial
        } catch {
            connection = .failed(ConnectionProblem(error))
            return nil
        }
    }

    func startMirroring() async {
        guard !isMirroring else { return }
        mirrorError = nil
        startAttempt = 0
        stoppedByUser = false
        await launchMirror()
    }

    private func launchMirror() async {
        startupTimedOut = false
        mirrorState = .starting
        guard let connected = await ensureConnected(), let serial = await freshConnection(replacing: connected),
              !stoppedByUser
        else {
            mirrorState = .idle
            return
        }

        do {
            mirrorProcess = try Scrcpy.launch(serial: serial, title: deviceName) { [weak self] failure in
                Task { @MainActor in self?.mirrorEnded(failure: failure) }
            }
            startupTask = Task { await waitForFirstFrame() }
        } catch {
            mirrorState = .idle
            mirrorError = error.localizedDescription
        }
    }

    private func freshConnection(replacing serial: String) async -> String? {
        guard !ADBOutputParser.isUSBSerial(serial) else { return serial }
        await ADB.disconnect(serial)
        connection = .idle
        return await ensureConnected()
    }

    private func waitForFirstFrame() async {
        guard let process = mirrorProcess else { return }
        let streaming = await Scrcpy.waitUntilStreaming(process, timeout: 12)
        guard mirrorState == .starting, process.isRunning else { return }
        if streaming {
            mirrorState = .running
            NSApp.hide(nil)
        } else {
            startupTimedOut = true
            process.terminate()
        }
    }

    func stopMirroring() {
        stoppedByUser = true
        startupTask?.cancel()
        guard let process = mirrorProcess, process.isRunning else {
            mirrorState = .idle
            return
        }
        process.terminate()
    }

    private func mirrorEnded(failure: String?) {
        startupTask?.cancel()
        mirrorProcess = nil
        let wasStarting = mirrorState == .starting

        if wasStarting, !stoppedByUser, startupTimedOut || failure != nil, startAttempt < Self.maxStartRetries {
            startAttempt += 1
            Task {
                try? await Task.sleep(for: .seconds(1))
                guard !stoppedByUser else { return }
                await launchMirror()
            }
            return
        }

        if !wasStarting {
            NSApp.unhide(nil)
            NSApp.activate()
        }
        mirrorState = .idle

        if startupTimedOut {
            connection = .failed(ConnectionProblem(ToolError.mirrorTimeout))
        } else if let failure, !stoppedByUser {
            mirrorError = failure
            connection = .idle
        }
    }

    private func save(_ device: PairedDevice) {
        pairedDevice = device
        if let data = try? JSONEncoder().encode(device) {
            UserDefaults.standard.set(data, forKey: Self.deviceKey)
        }
    }
}
