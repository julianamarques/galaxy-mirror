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
        }
    }
    @Published private(set) var mirrorError: String?

    lazy var setup = SetupModel(app: self)

    private var mirrorTask: Task<Void, Never>?
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
