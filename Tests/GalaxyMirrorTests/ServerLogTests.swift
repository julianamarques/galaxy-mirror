import Testing
@testable import GalaxyMirror

struct ServerLogTests {
    @Test func keepsErrorsAcrossChunks() {
        let log = ServerLog()
        log.append("[server] INFO: Device: SM-S931B\n[server] ERR")
        log.append("OR: Could not open video stream\n")

        #expect(log.lastError == "[server] ERROR: Could not open video stream")
    }

    @Test func reportsNothingWithoutErrors() {
        let log = ServerLog()
        log.append("[server] INFO: Device: SM-S931B\n")

        #expect(log.lastError == nil)
    }
}
