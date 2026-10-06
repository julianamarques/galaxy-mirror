import Foundation
import Testing
@testable import GalaxyMirror

struct ToolsTests {
    @Test func capturesStdoutAndStderr() async throws {
        let result = try await Tools.run(URL(fileURLWithPath: "/bin/sh"), ["-c", "echo out; echo err >&2"], timeout: 5)

        #expect(result.stdout == "out\n")
        #expect(result.stderr == "err\n")
        #expect(result.output == "out\nerr")
    }

    @Test func terminatesAfterTimeout() async throws {
        let start = Date()
        _ = try await Tools.run(URL(fileURLWithPath: "/bin/sleep"), ["10"], timeout: 0.5)

        #expect(Date().timeIntervalSince(start) < 5)
    }

    @Test func discardsOutputWhenNotCaptured() async throws {
        let result = try await Tools.run(URL(fileURLWithPath: "/bin/echo"), ["oi"], timeout: 5, captureOutput: false)

        #expect(result.output.isEmpty)
    }

    @Test func throwsWhenExecutableIsMissing() async {
        await #expect(throws: (any Error).self) {
            try await Tools.run(URL(fileURLWithPath: "/nonexistent/tool"), [], timeout: 5)
        }
    }
}
