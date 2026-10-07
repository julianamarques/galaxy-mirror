import AppKit
import AVFoundation

final class MirrorView: NSView, @preconcurrency NSTextInputClient {
    let session: MirrorSession
    private var markedText = ""

    init(session: MirrorSession) {
        self.session = session
        super.init(frame: .zero)
        layer = session.displayLayer
        wantsLayer = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    static func devicePosition(of point: CGPoint, in bounds: CGSize, videoSize: CGSize) -> ControlMessage.Position? {
        guard videoSize.width > 0, videoSize.height > 0, bounds.width > 0, bounds.height > 0 else { return nil }
        let video = AVMakeRect(aspectRatio: videoSize, insideRect: CGRect(origin: .zero, size: bounds))
        let x = (point.x - video.minX) * videoSize.width / video.width
        let y = (point.y - video.minY) * videoSize.height / video.height
        return ControlMessage.Position(
            x: Int32(min(max(x, 0), videoSize.width - 1)),
            y: Int32(min(max(y, 0), videoSize.height - 1)),
            screenWidth: UInt16(videoSize.width),
            screenHeight: UInt16(videoSize.height)
        )
    }

    private func position(of event: NSEvent) -> ControlMessage.Position? {
        Self.devicePosition(of: convert(event.locationInWindow, from: nil), in: bounds.size, videoSize: session.videoSize)
    }

    private func touch(_ action: ControlMessage.TouchAction, _ event: NSEvent) {
        guard let position = position(of: event) else { return }
        session.send(.touch(
            action: action,
            pointerID: ControlMessage.mousePointerID,
            position: position,
            pressure: action == .up ? 0 : 1,
            actionButton: action == .move ? 0 : ControlMessage.primaryButton,
            buttons: action == .up ? 0 : ControlMessage.primaryButton
        ))
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        touch(.down, event)
    }

    override func mouseDragged(with event: NSEvent) { touch(.move, event) }
    override func mouseUp(with event: NSEvent) { touch(.up, event) }
    override func rightMouseDown(with event: NSEvent) { session.send(.backOrScreenOn(action: .down)) }
    override func rightMouseUp(with event: NSEvent) { session.send(.backOrScreenOn(action: .up)) }
    override func otherMouseDown(with event: NSEvent) { session.send(.keycode(action: .down, keycode: AndroidKeycode.home.rawValue)) }
    override func otherMouseUp(with event: NSEvent) { session.send(.keycode(action: .up, keycode: AndroidKeycode.home.rawValue)) }

    override func scrollWheel(with event: NSEvent) {
        guard let position = position(of: event) else { return }
        let divisor: CGFloat = event.hasPreciseScrollingDeltas ? 10 : 1
        session.send(.scroll(
            position: position,
            horizontal: Float(event.scrollingDeltaX / divisor),
            vertical: Float(event.scrollingDeltaY / divisor),
            buttons: 0
        ))
    }

    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command) {
            super.keyDown(with: event)
        } else if !hasMarkedText(), sendKey(.down, for: event) {
            return
        } else {
            interpretKeyEvents([event])
        }
    }

    override func keyUp(with event: NSEvent) {
        if !event.modifierFlags.contains(.command) {
            sendKey(.up, for: event)
        }
    }

    @discardableResult
    private func sendKey(_ action: ControlMessage.KeyAction, for event: NSEvent) -> Bool {
        guard let keycode = AndroidKeycode(macKeyCode: event.keyCode) else { return false }
        session.send(.keycode(
            action: action,
            keycode: keycode.rawValue,
            repeatCount: event.isARepeat ? 1 : 0,
            metaState: AndroidKeycode.metaState(for: event.modifierFlags)
        ))
        return true
    }

    @objc func paste(_ sender: Any?) {
        guard let text = NSPasteboard.general.string(forType: .string) else { return }
        session.paste(text)
    }

    override func doCommand(by selector: Selector) {}

    private static func plainText(_ string: Any) -> String {
        (string as? NSAttributedString)?.string ?? (string as? String) ?? ""
    }

    func insertText(_ string: Any, replacementRange: NSRange) {
        markedText = ""
        let text = Self.plainText(string)
        guard !text.isEmpty else { return }
        session.send(.text(text))
    }

    func setMarkedText(_ string: Any, selectedRange: NSRange, replacementRange: NSRange) {
        markedText = Self.plainText(string)
    }

    func unmarkText() { markedText = "" }
    func selectedRange() -> NSRange { NSRange(location: NSNotFound, length: 0) }
    func markedRange() -> NSRange { hasMarkedText() ? NSRange(location: 0, length: markedText.utf16.count) : NSRange(location: NSNotFound, length: 0) }
    func hasMarkedText() -> Bool { !markedText.isEmpty }
    func attributedSubstring(forProposedRange range: NSRange, actualRange: NSRangePointer?) -> NSAttributedString? { nil }
    func validAttributesForMarkedText() -> [NSAttributedString.Key] { [] }
    func characterIndex(for point: NSPoint) -> Int { NSNotFound }

    func firstRect(forCharacterRange range: NSRange, actualRange: NSRangePointer?) -> NSRect {
        window?.convertToScreen(convert(NSRect(x: bounds.midX, y: bounds.midY, width: 0, height: 0), to: nil)) ?? .zero
    }
}
