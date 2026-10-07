import Foundation
import Testing
@testable import GalaxyMirror

struct ControlMessageTests {
    private let position = ControlMessage.Position(x: 100, y: 200, screenWidth: 1080, screenHeight: 1920)

    @Test func encodesKeycode() {
        let data = ControlMessage.keycode(action: .up, keycode: 66, repeatCount: 5, metaState: 0x41).data

        #expect(Array(data) == [0, 1, 0, 0, 0, 66, 0, 0, 0, 5, 0, 0, 0, 0x41])
    }

    @Test func encodesText() {
        #expect(Array(ControlMessage.text("olá").data) == [1, 0, 0, 0, 4, 0x6F, 0x6C, 0xC3, 0xA1])
    }

    @Test func truncatesTextOnCharacterBoundaries() {
        #expect(ControlMessage.truncated("ãããã", toBytes: 5) == "ãã")
    }

    @Test func encodesTouchEvent() {
        let data = ControlMessage.touch(
            action: .down, pointerID: ControlMessage.mousePointerID, position: position,
            pressure: 1, actionButton: 1, buttons: 1
        ).data

        #expect(data.count == 32)
        #expect(Array(data) == [
            2, 0,
            0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
            0, 0, 0, 100, 0, 0, 0, 200, 0x04, 0x38, 0x07, 0x80,
            0xFF, 0xFF,
            0, 0, 0, 1,
            0, 0, 0, 1,
        ])
    }

    @Test func encodesScrollEvent() {
        let data = ControlMessage.scroll(position: position, horizontal: 16, vertical: -8, buttons: 0).data

        #expect(data.count == 21)
        #expect(Array(data[13..<17]) == [0x7F, 0xFF, 0xC0, 0x00])
    }

    @Test func encodesClipboardPaste() {
        let data = ControlMessage.setClipboard(sequence: 7, text: "oi", paste: true).data

        #expect(Array(data) == [9, 0, 0, 0, 0, 0, 0, 0, 7, 1, 0, 0, 0, 2, 0x6F, 0x69])
    }

    @Test func encodesDisplayPowerAndBack() {
        #expect(Array(ControlMessage.setDisplayPower(on: false).data) == [10, 0])
        #expect(Array(ControlMessage.backOrScreenOn(action: .down).data) == [4, 0])
        #expect(Array(ControlMessage.resetVideo.data) == [17])
    }

    @Test func convertsFixedPoint() {
        #expect(ControlMessage.unsignedFixedPoint(0) == 0)
        #expect(ControlMessage.unsignedFixedPoint(0.5) == 0x8000)
        #expect(ControlMessage.unsignedFixedPoint(1) == 0xFFFF)
        #expect(ControlMessage.signedFixedPoint(-1) == -32768)
        #expect(ControlMessage.signedFixedPoint(2) == 0x7FFF)
    }
}
