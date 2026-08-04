import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: NSPanel!
    private var commandField: NSTextField!

    private let panelWidth: CGFloat = 300
    private let fallbackHeight: CGFloat = 64

    func applicationDidFinishLaunching(_ notification: Notification) {
        let height = dockHeight() ?? fallbackHeight
        let frame = panelFrame(height: height)

        let panel = KeyablePanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isMovable = false
        // Present on every Space, including full-screen ones, and skip
        // the app switcher / window cycling entirely.
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        panel.hidesOnDeactivate = false

        let effectView = NSVisualEffectView(frame: NSRect(origin: .zero, size: frame.size))
        effectView.autoresizingMask = [.width, .height]
        effectView.material = .hudWindow
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        effectView.wantsLayer = true
        effectView.layer?.cornerRadius = 12
        effectView.layer?.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]

        let field = NSTextField(frame: effectView.bounds.insetBy(dx: 16, dy: 0))
        field.autoresizingMask = [.width, .height]
        field.isBordered = false
        field.isBezeled = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        field.textColor = .labelColor
        field.placeholderString = "$"
        field.target = self
        field.action = #selector(runCommand(_:))

        effectView.addSubview(field)
        panel.contentView = effectView

        self.panel = panel
        self.commandField = field

        panel.orderFrontRegardless()
        panel.makeFirstResponder(field)
    }

    /// Height of the Dock at the bottom of the main screen, derived from
    /// the gap between the screen's full frame and its visible frame.
    /// Falls back to nil if the Dock isn't on the bottom edge (or is
    /// auto-hidden), so callers can use a sensible default instead.
    private func dockHeight() -> CGFloat? {
        guard let screen = NSScreen.main else { return nil }
        let height = screen.visibleFrame.minY - screen.frame.minY
        return height > 4 ? height : nil
    }

    private func panelFrame(height: CGFloat) -> NSRect {
        guard let screen = NSScreen.main else {
            return NSRect(x: 0, y: 0, width: panelWidth, height: height)
        }
        let x = screen.frame.maxX - panelWidth
        let y = screen.frame.minY
        return NSRect(x: x, y: y, width: panelWidth, height: height)
    }

    @objc private func runCommand(_ sender: NSTextField) {
        let command = sender.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        sender.stringValue = ""
        guard !command.isEmpty else { return }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", command]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        process.standardInput = FileHandle.nullDevice
        // Reaps the child on exit; output is intentionally discarded.
        process.terminationHandler = { _ in }

        try? process.run()
    }
}
