import AppKit

@MainActor
final class MirrorWindowController: NSWindowController, NSWindowDelegate {
    var onClose: (() -> Void)?

    private let session: MirrorSession
    private let mirrorView: MirrorView

    init(session: MirrorSession, title: String, alwaysOnTop: Bool) {
        self.session = session
        mirrorView = MirrorView(session: session)

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: Self.initialSize(for: session.videoSize)),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = title
        window.contentView = mirrorView
        window.level = alwaysOnTop ? .floating : .normal
        window.backgroundColor = .black
        window.isReleasedWhenClosed = false
        window.setFrameAutosaveName("GalaxyMirrorWindow")
        super.init(window: window)

        window.delegate = self
        window.addTitlebarAccessoryViewController(navigationAccessory())
        if !window.setFrameUsingName("GalaxyMirrorWindow") { window.center() }
        session.onVideoSizeChange = { [weak self] size in self?.videoSizeChanged(size) }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func present() {
        showWindow(nil)
        window?.makeFirstResponder(mirrorView)
        NSApp.activate()
    }

    private func videoSizeChanged(_ size: CGSize) {
        guard let window, size.width > 0, size.height > 0 else { return }
        let height = window.contentLayoutRect.height
        window.contentAspectRatio = size
        var frame = window.frame
        let contentSize = NSSize(width: height * size.width / size.height, height: height)
        frame.size = window.frameRect(forContentRect: NSRect(origin: .zero, size: contentSize)).size
        window.setFrame(frame, display: true, animate: false)
    }

    func closeWithoutNotifying() {
        onClose = nil
        close()
    }

    func windowWillClose(_ notification: Notification) {
        onClose?()
    }

    private static func initialSize(for videoSize: CGSize) -> NSSize {
        let available = NSScreen.main?.visibleFrame.height ?? 900
        let height = (available * 0.8).rounded()
        guard videoSize.height > 0 else { return NSSize(width: height * 9 / 19.5, height: height) }
        return NSSize(width: (height * videoSize.width / videoSize.height).rounded(), height: height)
    }

    private func navigationAccessory() -> NSTitlebarAccessoryViewController {
        let buttons = [
            button("chevron.backward", label: "Voltar", keycode: .back),
            button("circle", label: "Início", keycode: .home),
            button("square.on.square", label: "Recentes", keycode: .appSwitch),
        ]
        let stack = NSStackView(views: buttons)
        stack.spacing = 2
        stack.edgeInsets = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 6)
        stack.frame = NSRect(origin: .zero, size: NSSize(width: stack.fittingSize.width, height: 28))
        let accessory = NSTitlebarAccessoryViewController()
        accessory.view = stack
        accessory.layoutAttribute = .trailing
        return accessory
    }

    private func button(_ symbol: String, label: String, keycode: AndroidKeycode) -> NSButton {
        let button = NSButton(image: NSImage(systemSymbolName: symbol, accessibilityDescription: label)!, target: self, action: #selector(navigate(_:)))
        button.tag = Int(keycode.rawValue)
        button.isBordered = false
        button.toolTip = label
        button.setButtonType(.momentaryPushIn)
        return button
    }

    @objc private func navigate(_ sender: NSButton) {
        if let keycode = AndroidKeycode(rawValue: Int32(sender.tag)) {
            session.sendKey(keycode)
        }
    }
}
