import Cocoa
import ApplicationServices
import SwiftTerm

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: NSPanel!
    private var terminalView: LocalProcessTerminalView!
    private var trackingTimer: Timer!

    private let fallbackWidth: CGFloat = 300
    private let fallbackHeight: CGFloat = 64
    private let fallbackMargin: CGFloat = 8
    private let cornerRadius: CGFloat = 12
    private let dockTrackingInterval: TimeInterval = 1.0
    /// Empirical corrections for the gap between the Dock's AXList (icon
    /// row) bounding box and its actual painted chrome, which Accessibility
    /// doesn't expose directly. Tuned against a real Dock; nudge these if
    /// the panel's edges drift from the Dock's over time or on other
    /// displays/tile sizes.
    private let dockBottomCorrection: CGFloat = 6
    private let dockTopCorrection: CGFloat = 4

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Triggers the system Accessibility permission prompt on first
        // launch if not already granted. Needed to read the Dock's icon
        // tray geometry precisely; falls back to an approximation until
        // it's granted (see fallbackFrame below).
        let promptOptions = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(promptOptions)

        let panel = KeyablePanel(
            contentRect: currentFrame(),
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

        let effectView = NSVisualEffectView(frame: NSRect(origin: .zero, size: panel.frame.size))
        effectView.autoresizingMask = [.width, .height]
        effectView.material = .hudWindow
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        effectView.wantsLayer = true
        effectView.layer?.cornerRadius = cornerRadius
        // Clip subviews to the rounded shape too — otherwise the terminal
        // view (which fills the whole panel edge-to-edge) can paint square
        // corners over the rounded blur.
        effectView.layer?.masksToBounds = true

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

        let timer = Timer(timeInterval: dockTrackingInterval, repeats: true) { [weak self] _ in
            self?.syncFrameToDock()
        }
        RunLoop.main.add(timer, forMode: .common)
        trackingTimer = timer
    }

    private func syncFrameToDock() {
        let frame = currentFrame()
        guard panel.frame != frame else { return }
        panel.setFrame(frame, display: true)
    }

    /// Sizes and positions the panel as a companion to the Dock: same
    /// height, same bottom margin (so they sit on one baseline), left edge
    /// touching the Dock's right edge, and that same margin held on the
    /// panel's own right edge.
    private func currentFrame() -> NSRect {
        guard let screen = NSScreen.main else {
            return NSRect(x: 0, y: 0, width: fallbackWidth, height: fallbackHeight)
        }

        guard let rawDock = dockIconTrayFrame() else {
            return fallbackFrame(on: screen)
        }
        // The AXList's box doesn't quite match the Dock's painted chrome
        // on either edge: its bottom sits above the Dock's real bottom
        // margin, and its top overshoots above the Dock's real top edge
        // (by a smaller amount) — independently tuned corrections for each.
        let minY = rawDock.minY - dockBottomCorrection
        let maxY = rawDock.maxY - dockTopCorrection
        let dock = NSRect(x: rawDock.minX, y: minY, width: rawDock.width, height: maxY - minY)

        let margin = dock.minY - screen.frame.minY
        let x = dock.maxX
        let width = max(screen.frame.maxX - margin - x, 0)
        return NSRect(x: x, y: dock.minY, width: width, height: dock.height)
    }

    /// Used before Accessibility permission is granted (or if the Dock's
    /// AX tree is ever unavailable). The height macOS reserves for the
    /// Dock is still readable without any special permission, from the gap
    /// between the screen's full frame and its visible frame — just not
    /// the Dock's actual width, so this can't touch its right edge.
    private func fallbackFrame(on screen: NSScreen) -> NSRect {
        let reserved = screen.visibleFrame.minY - screen.frame.minY
        let height = reserved > 4 ? reserved : fallbackHeight
        let x = screen.frame.maxX - fallbackWidth - fallbackMargin
        let y = screen.frame.minY + fallbackMargin
        return NSRect(x: x, y: y, width: fallbackWidth, height: height)
    }

    /// Tight bounding box of the Dock's icon tray — the `AXList` child of
    /// the Dock process's accessibility tree — read via the Accessibility
    /// API. This is deliberately not the Dock's own window frame: on
    /// modern macOS that frame spans the entire screen (the Dock process
    /// also hosts desktop wallpaper/icon interaction), which is useless
    /// for positioning. Returns nil if Accessibility permission hasn't
    /// been granted yet, or the Dock's AX tree can't be read.
    private func dockIconTrayFrame() -> NSRect? {
        guard let screen = NSScreen.main else { return nil }
        guard let dockApp = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == "com.apple.dock" }) else {
            return nil
        }

        let axApp = AXUIElementCreateApplication(dockApp.processIdentifier)

        var childrenRef: AnyObject?
        guard AXUIElementCopyAttributeValue(axApp, kAXChildrenAttribute as CFString, &childrenRef) == .success,
              let children = childrenRef as? [AXUIElement]
        else {
            return nil
        }

        guard let list = children.first(where: { axRole(of: $0) == (kAXListRole as String) }) else {
            return nil
        }

        guard let position = axPoint(list, kAXPositionAttribute as CFString),
              let size = axSize(list, kAXSizeAttribute as CFString)
        else {
            return nil
        }

        // AX coordinates are Quartz's top-left-origin space; flip to
        // AppKit's bottom-left-origin space.
        let flippedY = screen.frame.height - position.y - size.height
        return NSRect(x: position.x, y: flippedY, width: size.width, height: size.height)
    }

    private func axRole(of element: AXUIElement) -> String? {
        var roleRef: AnyObject?
        guard AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef) == .success else {
            return nil
        }
        return roleRef as? String
    }

    private func axPoint(_ element: AXUIElement, _ attribute: CFString) -> CGPoint? {
        var valueRef: AnyObject?
        guard AXUIElementCopyAttributeValue(element, attribute, &valueRef) == .success,
              let axValue = valueRef
        else {
            return nil
        }
        var point = CGPoint.zero
        guard AXValueGetValue(axValue as! AXValue, .cgPoint, &point) else { return nil }
        return point
    }

    private func axSize(_ element: AXUIElement, _ attribute: CFString) -> CGSize? {
        var valueRef: AnyObject?
        guard AXUIElementCopyAttributeValue(element, attribute, &valueRef) == .success,
              let axValue = valueRef
        else {
            return nil
        }
        var size = CGSize.zero
        guard AXValueGetValue(axValue as! AXValue, .cgSize, &size) else { return nil }
        return size
    }
}
