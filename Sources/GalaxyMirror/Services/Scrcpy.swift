import Foundation

enum Scrcpy {
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

        let log = FileManager.default.temporaryDirectory.appendingPathComponent("GalaxyMirror-scrcpy.log")
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

    private static func errorSummary(_ log: URL) -> String {
        let errors = ((try? String(contentsOf: log, encoding: .utf8)) ?? "")
            .split(separator: "\n")
            .filter { $0.contains("ERROR") }
            .suffix(3)
            .joined(separator: "\n")
        return errors.isEmpty ? "O espelhamento foi encerrado inesperadamente." : errors
    }
}
