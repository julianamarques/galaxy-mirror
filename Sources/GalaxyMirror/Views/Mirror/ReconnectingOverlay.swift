import AppKit

final class ReconnectingOverlay: NSVisualEffectView {
    private let spinner = NSProgressIndicator()

    init() {
        super.init(frame: .zero)
        material = .hudWindow
        blendingMode = .withinWindow
        state = .active
        autoresizingMask = [.width, .height]

        spinner.style = .spinning
        spinner.controlSize = .regular
        let label = NSTextField(labelWithString: "Reconectando…")
        label.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .medium)
        label.textColor = .labelColor

        let stack = NSStackView(views: [spinner, label])
        stack.orientation = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        isHidden = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func show() {
        isHidden = false
        spinner.startAnimation(nil)
    }

    func hide() {
        isHidden = true
        spinner.stopAnimation(nil)
    }
}
