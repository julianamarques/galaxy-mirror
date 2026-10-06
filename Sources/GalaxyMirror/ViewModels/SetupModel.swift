import Foundation

@MainActor
final class SetupModel: ObservableObject {
    enum Step: Equatable {
        case welcome
        case missingTools
        case prepare
        case pair
        case connecting
        case failed(String)
        case done
    }

    enum PairingMode { case qr, code }

    @Published var step: Step = .welcome
    @Published var mode: PairingMode = .qr
    @Published private(set) var discovered: [MDNSService] = []
    @Published var selectedAddress: String?
    @Published var manualAddress = ""
    @Published var code = "" {
        didSet {
            let digits = String(code.filter(\.isNumber).prefix(6))
            if digits != code { code = digits }
        }
    }
    @Published private(set) var isPairing = false
    @Published private(set) var codeError: String?

    private(set) var qrName = ""
    private(set) var qrPassword = ""
    private(set) var qrPayload = ""

    private unowned let app: AppModel
    private var pollTask: Task<Void, Never>?

    init(app: AppModel) {
        self.app = app
        makeCredentials()
        #if DEBUG
        switch ProcessInfo.processInfo.environment["GALAXY_STEP"] {
        case "prepare": step = .prepare
        case "pair": beginPairing()
        case "code": mode = .code; beginPairing()
        case "connecting": step = .connecting
        case "failed": step = .failed("failed to connect to 192.168.0.10:41235")
        case "done": step = .done
        case "missing": step = .missingTools
        default: break
        }
        #endif
    }

    func continueFromWelcome() {
        step = Tools.isInstalled ? .prepare : .missingTools
    }

    func beginPairing() {
        step = .pair
        codeError = nil
        startPolling()
    }

    func retry() {
        if Tools.isInstalled { beginPairing() } else { step = .missingTools }
    }

    func cancel() {
        stopPolling()
        step = .welcome
    }

    func reset() {
        cancel()
        mode = .qr
        discovered = []
        selectedAddress = nil
        manualAddress = ""
        code = ""
        codeError = nil
        makeCredentials()
    }

    private func makeCredentials() {
        qrName = "studio-" + String.random(8)
        qrPassword = String.random(12)
        qrPayload = "WIFI:T:ADB;S:\(qrName);P:\(qrPassword);;"
    }

    private func startPolling() {
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self, self.step == .pair else { return }
                let services = await ADB.mdnsServices().filter(\.isPairing)
                let discovered = services.filter { $0.name != self.qrName }
                if discovered != self.discovered { self.discovered = discovered }
                if !discovered.contains(where: { $0.address == self.selectedAddress }) {
                    self.selectedAddress = discovered.first?.address
                }
                if !self.isPairing, let qr = services.first(where: { $0.name == self.qrName }) {
                    await self.pair(address: qr.address, code: self.qrPassword)
                    return
                }
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    private func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }

    var canSubmitCode: Bool {
        code.count == 6 && pairingAddress != nil && !isPairing
    }

    private var pairingAddress: String? {
        let manual = manualAddress.trimmingCharacters(in: .whitespaces)
        if !manual.isEmpty { return manual }
        return selectedAddress
    }

    func submitCode() {
        guard canSubmitCode, let address = pairingAddress else { return }
        stopPolling()
        Task { await pair(address: address, code: code) }
    }

    private func pair(address: String, code: String) async {
        isPairing = true
        codeError = nil
        defer { isPairing = false }

        let guid: String?
        do {
            guid = try await ADB.pair(address: address, code: code)
        } catch {
            guard !Task.isCancelled else { return }
            if mode == .code {
                codeError = error.localizedDescription
                startPolling()
            } else {
                step = .failed(error.localizedDescription)
            }
            return
        }

        step = .connecting
        do {
            let serial = try await ADB.waitForConnection(guid: guid, host: ADBOutputParser.host(of: address))
            let name = await ADB.deviceName(serial)
            let device = PairedDevice(guid: guid, name: name, lastAddress: ADBOutputParser.networkAddress(serial))
            app.didPair(device, serial: serial)
            step = .done
        } catch {
            guard !Task.isCancelled else { return }
            step = .failed(error.localizedDescription)
        }
    }
}
