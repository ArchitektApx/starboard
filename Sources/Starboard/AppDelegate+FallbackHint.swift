import Cocoa

extension AppDelegate {
    static let fallbackHintOverlap: CGFloat = 6
    static let fallbackHintMessage = """
        This is Starboard — a terminal that lives beside your Dock, on screen, on every desktop, always on.

        It needs Accessibility permission to track the Dock's position and size, nothing else. macOS will ask in a moment.

        ⌘E expands it. ⌘T opens themes. ⌘Q quits.

        Not glued to Dock? Remove Starboard in System Settings → Accessibility, then re-add it.
        """

    func installFallbackHintIfNeeded() {
        guard hintPanel == nil else { return }
        let (hint, tintView, label) = FallbackHintPanel.make(
            message: Self.fallbackHintMessage, width: Self.fallbackWidth, theme: currentTheme,
            target: self, action: #selector(dismissFallbackHint))
        hintPanel = hint
        hintTintView = tintView
        hintLabel = label
    }

    func applyThemeToFallbackHint(_ theme: Theme) {
        hintTintView?.layer?.backgroundColor = theme.panelTintColor.cgColor
        hintLabel?.textColor = theme.foregroundColor
    }

    @objc func dismissFallbackHint() {
        hintDismissed = true
        guard let hint = hintPanel else { return }
        panel.removeChildWindow(hint)
        hint.orderOut(nil)
    }

    func updateFallbackHintVisibility() {
        guard !accessibilityTrusted, !hintDismissed, let hint = hintPanel else {
            hintPanel?.orderOut(nil)
            return
        }
        guard panel.isVisible, lastPresenceUntracked, !isExpanded else {
            hint.orderOut(nil)
            return
        }
        positionFallbackHint()
        if hint.parent !== panel {
            panel.addChildWindow(hint, ordered: .below)
        }
        hint.orderFront(nil)
    }

    func positionFallbackHint() {
        guard let hint = hintPanel else { return }
        let mainFrame = panel.frame
        hint.setFrameOrigin(
            NSPoint(x: mainFrame.minX, y: mainFrame.maxY - Self.fallbackHintOverlap))
    }
}
