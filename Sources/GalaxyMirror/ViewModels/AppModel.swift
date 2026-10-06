import AppKit

@MainActor
final class AppModel: ObservableObject {
    enum Connection: Equatable {
        case idle
        case connecting
        case connected(serial: String)
        case failed(String)
    }

    @Published private(set) var pairedDevice: PairedDevice?
    @Published var showingSetup: Bool
    @Published private(set) var connection: Connection = .idle
    @Published private var mirrorProcess: Process?
    @Published private(set) var mirrorError: String?

    lazy var setup = SetupModel(app: self)

    private var stoppedByUser = false
    private static let deviceKey = "pairedDevice"

    init() {
        SettingsKey.register()
        let device = UserDefaults.standard.data(forKey: Self.deviceKey)
            .flatMap { try? JSONDecoder().decode(PairedDevice.self, from: $0) }
        pairedDevice = device
        showingSetup = device == nil
    }

    var deviceName: String { pairedDevice?.name ?? "Galaxy" }
    var isMirroring: Bool { mirrorProcess != nil }

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
        if case .connected(let serial) = connection, await ADB.isReady(serial) {
            return serial
        }
        guard var device = pairedDevice else { return nil }

        connection = .connecting
        do {
            let serial = try await ADB.waitForConnection(guid: device.guid, lastAddress: device.lastAddress)
            if let address = ADBOutputParser.networkAddress(serial) {
                device.lastAddress = address
                save(device)
            }
            connection = .connected(serial: serial)
            return serial
        } catch {
            connection = .failed(error.localizedDescription)
            return nil
        }
    }

    func startMirroring() async {
        guard !isMirroring else { return }
        mirrorError = nil
        guard let serial = await ensureConnected() else { return }

        do {
            stoppedByUser = false
            mirrorProcess = try Scrcpy.launch(serial: serial, title: deviceName) { [weak self] failure in
                Task { @MainActor in self?.mirrorEnded(failure: failure) }
            }
            NSApp.hide(nil)
        } catch {
            mirrorError = error.localizedDescription
        }
    }

    func stopMirroring() {
        guard let process = mirrorProcess, process.isRunning else { return }
        stoppedByUser = true
        process.terminate()
    }

    private func mirrorEnded(failure: String?) {
        mirrorProcess = nil
        NSApp.unhide(nil)
        NSApp.activate()

        if let failure, !stoppedByUser {
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
