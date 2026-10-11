import AppKit

@MainActor
final class MirrorWindowController: NSWindowController, NSWindowDelegate {
    var onClose: (() -> Void)?

    private let container = NSView()
    private let overlay = ReconnectingOverlay()
    private var mirrorView: MirrorView?
    private var pendingView: MirrorView?

    init(title: String, alwaysOnTop: Bool) {
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: Self.initialSize()),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = title
        container.wantsLayer = true
        window.contentView = container
        overlay.frame = container.bounds
        container.addSubview(overlay)
        window.level = alwaysOnTop ? .floating : .normal
        window.backgroundColor = .black
        window.isReleasedWhenClosed = false
        window.setFrameAutosaveName("GalaxyMirrorWindow")
        super.init(window: window)

        window.delegate = self
        window.addTitlebarAccessoryViewController(navigationAccessory())
        if !window.setFrameUsingName("GalaxyMirrorWindow") { window.center() }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func attach(_ session: MirrorSession) {
        let view = MirrorView(session: session)
        view.frame = container.bounds
        view.autoresizingMask = [.width, .height]
        pendingView?.removeFromSuperview()
        container.addSubview(view, positioned: .below, relativeTo: mirrorView ?? overlay)
        pendingView = view
        session.onVideoSizeChange = { [weak self] size in self?.videoSizeChanged(size) }
    }

    func sessionDidStart() {
        if let pendingView {
            mirrorView?.removeFromSuperview()
            mirrorView = pendingView
            self.pendingView = nil
        }
        overlay.hide()
        if window?.isVisible != true {
            showWindow(nil)
            NSApp.activate()
        }
        window?.makeFirstResponder(mirrorView)
    }

    func showReconnecting() {
        overlay.show()
    }

    private func videoSizeChanged(_ size: CGSize) {
        guard let window, size.width > 0, size.height > 0 else { return }
        let current = window.contentLayoutRect.size
        let screen = (window.screen ?? NSScreen.main)?.visibleFrame.size ?? NSSize(width: 1440, height: 900)
        let content = Self.fittedContentSize(
            for: size,
            longSide: max(current.width, current.height),
            maxSize: NSSize(width: screen.width * 0.9, height: screen.height * 0.9)
        )
        window.contentAspectRatio = size

        let center = NSPoint(x: window.frame.midX, y: window.frame.midY)
        var frame = window.frameRect(forContentRect: NSRect(origin: .zero, size: content))
        frame.origin = NSPoint(x: center.x - frame.width / 2, y: center.y - frame.height / 2)
        window.setFrame(window.constrainFrameRect(frame, to: window.screen), display: true, animate: true)
    }

    static func fittedContentSize(for video: CGSize, longSide: CGFloat, maxSize: CGSize) -> CGSize {
        let ratio = video.width / video.height
        var size = ratio >= 1
            ? CGSize(width: longSide, height: longSide / ratio)
            : CGSize(width: longSide * ratio, height: longSide)
        let scale = min(1, maxSize.width / size.width, maxSize.height / size.height)
        size = CGSize(width: size.width * scale, height: size.height * scale)
        return CGSize(width: size.width.rounded(), height: size.height.rounded())
    }

    func closeWithoutNotifying() {
        onClose = nil
        close()
    }

    func windowWillClose(_ notification: Notification) {
        onClose?()
    }

    private static func initialSize() -> NSSize {
        let screen = NSScreen.main?.visibleFrame.size ?? NSSize(width: 1440, height: 900)
        return fittedContentSize(
            for: CGSize(width: 9, height: 19.5),
            longSide: screen.height * 0.8,
            maxSize: NSSize(width: screen.width * 0.9, height: screen.height * 0.9)
        )
    }

    private func navigationAccessory() -> NSTitlebarAccessoryViewController {
        let buttons = [
            button("chevron.backward", label: String(localized: "Voltar"), keycode: .back),
            button("circle", label: String(localized: "Início"), keycode: .home),
            button("square.on.square", label: String(localized: "Recentes"), keycode: .appSwitch),
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
            mirrorView?.session.sendKey(keycode)
        }
    }
}
