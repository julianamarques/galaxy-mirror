import Testing
@testable import GalaxyMirror

struct DeviceMessageTests {
    private func reader(_ bytes: [UInt8]) -> (Int) throws -> [UInt8] {
        var remaining = bytes[...]
        return { count in
            let chunk = Array(remaining.prefix(count))
            remaining = remaining.dropFirst(count)
            return chunk
        }
    }

    @Test func readsClipboard() throws {
        let message = try DeviceMessage.read(using: reader([0, 0, 0, 0, 3, 0x61, 0x62, 0x63]))

        #expect(message == .clipboard("abc"))
    }

    @Test func readsClipboardAck() throws {
        let message = try DeviceMessage.read(using: reader([1, 0, 0, 0, 0, 0, 0, 0, 42]))

        #expect(message == .clipboardAck)
    }

    @Test func rejectsUnknownTypes() {
        #expect(throws: DeviceMessage.ParseError.self) {
            try DeviceMessage.read(using: reader([9]))
        }
    }
}
