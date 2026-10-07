import AppKit
import Testing
@testable import GalaxyMirror

struct AndroidKeycodeTests {
    @Test func mapsSpecialMacKeys() {
        #expect(AndroidKeycode(macKeyCode: 36) == .enter)
        #expect(AndroidKeycode(macKeyCode: 51) == .delete)
        #expect(AndroidKeycode(macKeyCode: 126) == .dpadUp)
        #expect(AndroidKeycode(macKeyCode: 0) == nil)
    }

    @Test func buildsMetaStateFromModifiers() {
        #expect(AndroidKeycode.metaState(for: []) == 0)
        #expect(AndroidKeycode.metaState(for: .shift) == 0x41)
        #expect(AndroidKeycode.metaState(for: [.shift, .option]) == 0x53)
    }
}
