import Cocoa
import SwiftTerm

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: NSPanel!
    private var terminalView: LocalProcessTerminalView!

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

        let terminal = LocalProcessTerminalView(frame: effectView.bounds)
        terminal.autoresizingMask = [.width, .height]
        // Let the blur behind the panel show through instead of the
        // terminal's own opaque background.
        terminal.nativeBackgroundColor = .clear
        terminal.nativeForegroundColor = .labelColor
        terminal.layer?.backgroundColor = NSColor.clear.cgColor

        effectView.addSubview(terminal)
        panel.contentView = effectView

        self.panel = panel
        self.terminalView = terminal

        panel.orderFrontRegardless()
        panel.makeFirstResponder(terminal)

        // A persistent login shell, not a new Process per command: cd/pwd
        // state survives between commands, same as a normal terminal tab.
        terminal.startProcess(executable: "/bin/zsh", args: ["-l"], currentDirectory: NSHomeDirectory())
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
}
