import CoreGraphics
import Foundation

enum Scrcpy {
    private static let log = FileManager.default.temporaryDirectory.appendingPathComponent("GalaxyMirror-scrcpy.log")

    static func launch(
        serial: String,
        title: String,
        onExit: @escaping @Sendable (_ failure: String?) -> Void
    ) throws -> Process {
        let process = Tools.makeProcess(
            try Tools.require("scrcpy"),
            MirrorArguments.make(serial: serial, title: title),
            environment: ["ADB": try Tools.require("adb").path]
        )

        FileManager.default.createFile(atPath: log.path, contents: nil)
        let output = try FileHandle(forWritingTo: log)
        process.standardOutput = output
        process.standardError = output
        process.terminationHandler = { process in
            try? output.close()
            onExit(process.terminationStatus == 0 ? nil : errorSummary(log))
        }

        try process.run()
        return process
    }

    static func waitForWindow(of process: Process, timeout: TimeInterval) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline, !Task.isCancelled, process.isRunning {
            if hasWindow(pid: process.processIdentifier) { return true }
            try? await Task.sleep(for: .milliseconds(300))
        }
        return false
    }

    private static func hasWindow(pid: pid_t) -> Bool {
        let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
        return windows.contains {
            ($0[kCGWindowOwnerPID as String] as? pid_t) == pid && ($0[kCGWindowLayer as String] as? Int) == 0
        }
    }

    private static func errorSummary(_ log: URL) -> String {
        let errors = ((try? String(contentsOf: log, encoding: .utf8)) ?? "")
            .split(separator: "\n")
            .filter { $0.contains("ERROR") }
            .suffix(3)
            .joined(separator: "\n")
        return errors.isEmpty ? "O espelhamento foi encerrado inesperadamente." : errors
    }
}
