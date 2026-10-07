import AppKit

@MainActor
final class AppModel: ObservableObject {
    enum Connection: Equatable {
        case idle
        case connecting
        case connected(serial: String)
        case failed(ConnectionProblem)
    }

    enum MirrorState { case idle, starting, running }

    @Published private(set) var pairedDevice: PairedDevice?
    @Published var showingSetup: Bool
    @Published private(set) var connection: Connection = .idle
    @Published private(set) var mirrorState: MirrorState = .idle {
        didSet {
            if mirrorState == .running, oldValue != .running { hideMainWindows() }
            if oldValue == .running, mirrorState != .running { showMainWindows() }
        }
    }
    @Published private(set) var mirrorError: String?

    lazy var setup = SetupModel(app: self)

    private var mirrorTask: Task<Void, Never>?
    private var session: MirrorSession?
    private var mirrorWindow: MirrorWindowController?
    private var hiddenWindows: [NSWindow] = []
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
                startMirroring()
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
        if start { startMirroring() }
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

    func startMirroring() {
        guard mirrorTask == nil else { return }
        mirrorError = nil
        mirrorTask = Task { await runMirror() }
    }

    func stopMirroring() {
        mirrorTask?.cancel()
        session?.stop()
    }

    private func runMirror() async {
        mirrorState = .starting
        defer {
            tearDownSession()
            mirrorState = .idle
            mirrorTask = nil
        }

        for attempt in 0...Self.maxStartRetries {
            do {
                if attempt > 0 { try await Task.sleep(for: .seconds(1)) }
                if let message = try await runSession() {
                    mirrorError = message
                    connection = .idle
                }
                return
            } catch is CancellationError {
                return
            } catch {
                tearDownSession()
                guard attempt == Self.maxStartRetries else { continue }
                if case ToolError.mirrorTimeout = error {
                    connection = .failed(ConnectionProblem(error))
                } else {
                    mirrorError = error.localizedDescription
                    connection = .idle
                }
            }
        }
    }

    private func runSession() async throws -> String? {
        guard let connected = await ensureConnected(), let serial = await freshConnection(replacing: connected) else {
            return nil
        }
        try Task.checkCancellation()

        let options = MirrorOptions()
        let connection = try await ScrcpyServer.start(serial: serial, options: options)
        let session = MirrorSession(connection: connection)
        let window = MirrorWindowController(session: session, title: deviceName, alwaysOnTop: options.alwaysOnTop)
        window.onClose = { [weak self] in self?.stopMirroring() }
        self.session = session
        mirrorWindow = window
        session.start()

        try await session.waitForFirstFrame(timeout: 12)
        mirrorState = .running
        window.present()
        if options.turnScreenOff {
            session.send(.setDisplayPower(on: false))
        }
        return await session.waitUntilEnded()
    }

    private func freshConnection(replacing serial: String) async -> String? {
        guard !ADBOutputParser.isUSBSerial(serial) else { return serial }
        await ADB.disconnect(serial)
        connection = .idle
        return await ensureConnected()
    }

    private func tearDownSession() {
        session?.stop()
        session = nil
        mirrorWindow?.closeWithoutNotifying()
        mirrorWindow = nil
    }

    private func hideMainWindows() {
        hiddenWindows = NSApp.windows.filter { $0.isVisible && $0 !== mirrorWindow?.window && $0.canBecomeMain }
        hiddenWindows.forEach { $0.orderOut(nil) }
    }

    private func showMainWindows() {
        hiddenWindows.forEach { $0.makeKeyAndOrderFront(nil) }
        hiddenWindows = []
    }

    private func save(_ device: PairedDevice) {
        pairedDevice = device
        if let data = try? JSONEncoder().encode(device) {
            UserDefaults.standard.set(data, forKey: Self.deviceKey)
        }
    }
}
