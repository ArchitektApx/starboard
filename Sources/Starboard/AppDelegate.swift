import ApplicationServices
import Cocoa
import CoreGraphics
import SwiftTerm

final class AppDelegate: NSObject, NSApplicationDelegate {
    var panel: NSPanel!
    var terminalView: LocalProcessTerminalView!
    var tintView: NSView!
    var trackingTimer: Timer!
    var currentTheme = Theme.theme(id: UserDefaults.standard.string(forKey: "themeID") ?? "")
    var themePickerPanel: KeyablePanel?

    var isExpanded = false
    var isFrozen = false
    var wasConcealed = false
    var expansionScreenID: CGDirectDisplayID?
    var collapsedFrame: NSRect?

    var cachedDockOrientation = "bottom"
    var cachedDockAutoHides = false
    var cachedDockHostScreenID: CGDirectDisplayID?
    var lastPresenceUntracked = true
    var tickCount = 0
    var lastDebugLine: [String: String] = [:]

    func applicationDidFinishLaunching(_ notification: Notification) {
        let promptOptions =
            [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        let accessibilityTrusted = AXIsProcessTrustedWithOptions(promptOptions)

        setUpMainMenu()

        refreshCoarseCaches()
        let initialPresence = resolveDockPresence()
        let initialFrame =
            initialPresence.map { frame(for: $0) }
            ?? NSRect(x: 0, y: 0, width: Self.fallbackWidth, height: Self.fallbackHeight)
        collapsedFrame = initialFrame
        lastPresenceUntracked = initialPresence?.isUntracked ?? true

        let (panel, terminal, tintView) = PanelBuilder.makePanel(
            initialFrame: initialFrame, theme: currentTheme)
        self.panel = panel
        self.terminalView = terminal
        self.tintView = tintView

        if case .concealed? = initialPresence {
            debugLog("visibility", "launching concealed (auto-hiding Dock is off screen)")
        } else {
            panel.orderFrontRegardless()
        }
        panel.makeFirstResponder(terminal)

        if !accessibilityTrusted {
            terminal.feed(
                text:
                    "Not glued to Dock? Remove Starboard in System Settings → Accessibility, then re-add it.\r\n"
            )
        }

        terminal.startProcess(
            executable: ShellEnvironment.executable,
            args: ["-l"],
            environment: ShellEnvironment.variables(),
            currentDirectory: NSHomeDirectory()
        )

        startTrackingTimer()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged(_:)),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
}
