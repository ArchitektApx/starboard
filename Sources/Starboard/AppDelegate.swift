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
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        let accessibilityTrusted = AXIsProcessTrusted()
        UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")

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
            let message =
                hasLaunchedBefore
                ? "Not glued to Dock? Remove Starboard in System Settings → Accessibility, then re-add it.\r\n"
                : "Starboard needs Accessibility permission to track the Dock's position and size — that's the only thing it reads. macOS will ask in a moment; grant it in System Settings → Privacy & Security → Accessibility and Starboard will snap in beside the Dock.\r\n\r\n"
            terminal.feed(text: message)
        }

        terminal.startProcess(
            executable: ShellEnvironment.executable,
            args: ["-l"],
            environment: ShellEnvironment.variables(),
            currentDirectory: NSHomeDirectory()
        )

        startTrackingTimer()

        if !accessibilityTrusted {
            let promptOptions =
                [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            let promptDelay: TimeInterval = hasLaunchedBefore ? 0 : 1.2
            DispatchQueue.main.asyncAfter(deadline: .now() + promptDelay) {
                _ = AXIsProcessTrustedWithOptions(promptOptions)
            }
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged(_:)),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
}
