import AppKit

@MainActor
final class AppModel: ObservableObject {
    enum Connection: Equatable {
        case idle
        case connecting
        case connected(serial: String)
        case failed(ConnectionProblem)
    }

    enum MirrorState {
        case idle, starting, running, reconnecting

        var showsMirrorWindow: Bool { self == .running || self == .reconnecting }
    }

    private enum SessionEnd {
        case stopped
        case noDevice
        case lost(String)
    }

    @Published private(set) var pairedDevice: PairedDevice?
    @Published var showingSetup: Bool
    @Published private(set) var connection: Connection = .idle
    @Published private(set) var mirrorState: MirrorState = .idle {
        didSet {
            if mirrorState.showsMirrorWindow, !oldValue.showsMirrorWindow { hideMainWindows() }
            if oldValue.showsMirrorWindow, !mirrorState.showsMirrorWindow { showMainWindows() }
            if mirrorState == .idle { refreshConnection() }
        }
    }
    @Published private(set) var mirrorError: String?

    lazy var setup = SetupModel(app: self)

    private var mirrorTask: Task<Void, Never>?
    private let deviceMonitor = DeviceMonitor()
    private var trackedDevices: [ADBDevice] = []
    private var session: MirrorSession?
    private var mirrorWindow: MirrorWindowController?
    private var hiddenWindows: [NSWindow] = []
    private static let maxStartRetries = 2
    private static let reconnectWindow: TimeInterval = 30
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
            startMonitoring()
            guard pairedDevice != nil, !showingSetup else { return }
            if UserDefaults.standard.bool(forKey: SettingsKey.autoStart) {
                startMirroring()
            } else {
                await ensureConnected()
            }
        }
    }

    private func startMonitoring() {
        deviceMonitor.start { [weak self] devices in
            DispatchQueue.main.async {
                MainActor.assumeIsolated { self?.devicesChanged(devices) }
            }
        }
    }

    func stopMonitoring() {
        deviceMonitor.stop()
    }

    private func devicesChanged(_ devices: [ADBDevice]) {
        trackedDevices = devices
        refreshConnection()
    }

    private func refreshConnection() {
        guard let device = pairedDevice, mirrorState == .idle, connection != .connecting else { return }
        let available = trackedDevices.filter { $0.isReady && device.matches($0.serial) }
        if let preferred = available.first(where: \.isUSB) ?? available.first {
            connection = .connected(serial: preferred.serial)
        } else if case .connected = connection {
            connection = .idle
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
        guard let device = pairedDevice else { return nil }

        if let usb = await ADB.usbDevices().first(where: { $0.isReady && device.matchesUSB($0.serial) }) {
            return await connected(to: usb.serial)
        }
        if case .connected(let serial) = connection, await ADB.isReady(serial) {
            return serial
        }
        connection = .connecting
        Log.mirror.info("Procurando o Galaxy (cabo\(device.supportsWiFi ? " e Wi-Fi" : "", privacy: .public))")

        do {
            let serial = try await ADB.waitForConnection(
                guid: device.guid,
                lastAddress: device.lastAddress,
                acceptsUSB: device.matchesUSB,
                timeout: device.supportsWiFi ? 20 : 10
            )
            return await connected(to: serial)
        } catch {
            let problem = device.supportsWiFi ? error : ToolError.usbNotConnected
            Log.mirror.error("Galaxy não encontrado: \(problem.localizedDescription, privacy: .public)")
            connection = .failed(ConnectionProblem(problem))
            return nil
        }
    }

    private func connected(to serial: String) async -> String {
        guard var device = pairedDevice else { return serial }
        if ADBOutputParser.isUSBSerial(serial) {
            if device.usbSerial != serial { device.usbSerial = serial }
            if device.guid != nil { await ADB.enableWirelessDebugging(serial: serial) }
        } else if let address = ADBOutputParser.networkAddress(serial) {
            device.lastAddress = address
        }
        save(device)
        Log.mirror.info("Conectado ao Galaxy por \(ADBOutputParser.isUSBSerial(serial) ? "cabo" : "Wi-Fi", privacy: .public): \(serial, privacy: .public)")
        connection = .connected(serial: serial)
        return serial
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
            mirrorWindow?.closeWithoutNotifying()
            mirrorWindow = nil
            mirrorState = .idle
            mirrorTask = nil
        }

        var attempt = 0
        var reconnectDeadline: Date?
        while true {
            do {
                if attempt > 0 { try await Task.sleep(for: .seconds(min(attempt, 4))) }
                switch try await runSession() {
                case .stopped:
                    return
                case .noDevice:
                    guard let reconnectDeadline, Date() < reconnectDeadline else { return }
                    attempt += 1
                case .lost(let message):
                    Log.mirror.error("Espelhamento caiu: \(message, privacy: .public)")
                    tearDownSession()
                    mirrorError = message
                    reconnectDeadline = Date().addingTimeInterval(Self.reconnectWindow)
                    attempt = 1
                    mirrorState = .reconnecting
                    mirrorWindow?.showReconnecting()
                }
            } catch is CancellationError {
                return
            } catch {
                Log.mirror.error("Tentativa \(attempt + 1) falhou: \(error.localizedDescription, privacy: .public)")
                tearDownSession()
                attempt += 1
                if let reconnectDeadline {
                    guard Date() >= reconnectDeadline else { continue }
                    connection = .idle
                    return
                }
                guard attempt > Self.maxStartRetries else { continue }
                if case ToolError.mirrorTimeout = error {
                    connection = .failed(ConnectionProblem(error))
                } else {
                    mirrorError = error.localizedDescription
                    connection = .idle
                }
                return
            }
        }
    }

    private func runSession() async throws -> SessionEnd {
        guard let connected = await ensureConnected(), let serial = await freshConnection(replacing: connected) else {
            return .noDevice
        }
        try Task.checkCancellation()

        let options = MirrorOptions()
        let connection = try await ScrcpyServer.start(serial: serial, options: options)
        let session = MirrorSession(connection: connection)
        self.session = session
        let window = mirrorWindow ?? makeMirrorWindow(options: options)
        window.attach(session)
        session.start()

        try await session.waitForFirstFrame(timeout: 12)
        mirrorError = nil
        mirrorState = .running
        window.sessionDidStart()
        if options.turnScreenOff {
            session.send(.setDisplayPower(on: false))
        }
        guard let message = await session.waitUntilEnded() else { return .stopped }
        return .lost(message)
    }

    private func makeMirrorWindow(options: MirrorOptions) -> MirrorWindowController {
        let window = MirrorWindowController(title: deviceName, alwaysOnTop: options.alwaysOnTop)
        window.onClose = { [weak self] in self?.stopMirroring() }
        mirrorWindow = window
        return window
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
