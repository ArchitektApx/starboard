import Cocoa
import CoreGraphics
import SwiftTerm

enum PanelBuilder {
    static func makePanel(initialFrame: NSRect) -> (
        panel: KeyablePanel, terminal: LocalProcessTerminalView
    ) {
        let panel = KeyablePanel(
            contentRect: initialFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = NSWindow.Level(rawValue: Int(kCGDockWindowLevel) + 1)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isMovable = false
        panel.collectionBehavior = [
            .canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle,
        ]
        panel.hidesOnDeactivate = false

        let effectView = NSVisualEffectView(frame: NSRect(origin: .zero, size: panel.frame.size))
        effectView.autoresizingMask = [.width, .height]
        effectView.material = .menu
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        effectView.wantsLayer = true
        effectView.layer?.cornerRadius = TerminalTheme.cornerRadius
        effectView.layer?.masksToBounds = true
        effectView.layer?.borderWidth = 1
        effectView.layer?.borderColor = NSColor.white.withAlphaComponent(0.2).cgColor

        let tintView = NSView(frame: effectView.bounds)
        tintView.autoresizingMask = [.width, .height]
        tintView.wantsLayer = true
        tintView.layer?.backgroundColor = TerminalTheme.panelTintColor.cgColor
        effectView.addSubview(tintView)

        let terminal = LocalProcessTerminalView(
            frame: TerminalLayout.contentFrame(in: effectView.bounds))
        terminal.autoresizingMask = [.width]
        terminal.font = TerminalTheme.font
        terminal.nativeBackgroundColor = .clear
        terminal.nativeForegroundColor = .labelColor
        terminal.layer?.backgroundColor = NSColor.clear.cgColor
        terminal.installColors(TerminalTheme.ansiPalette)
        terminal.toolTip = "⌘E expand · ⌘Q quit"

        effectView.addSubview(terminal)
        panel.contentView = effectView

        return (panel, terminal)
    }
}
