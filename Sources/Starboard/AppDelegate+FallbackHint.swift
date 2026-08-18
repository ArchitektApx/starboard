import Cocoa

extension AppDelegate {
    static let fallbackHintOverlap: CGFloat = 6
    static let fallbackHintNudgeMessage =
        "Not glued to Dock? Remove Starboard in System Settings → Accessibility, then re-add it."
    static let fallbackHintWelcomeMessage = """
        This is Starboard — a terminal that lives beside your Dock, on screen, on every desktop, always on.

        It needs Accessibility permission to track the Dock's position and size, nothing else. macOS will ask in a moment.

        ⌘E expands it. ⌘T opens themes.
        """

    func installFallbackHintIfNeeded(hasLaunchedBefore: Bool) {
        guard hintPanel == nil else { return }
        let message = hasLaunchedBefore ? Self.fallbackHintNudgeMessage : Self.fallbackHintWelcomeMessage
        let (hint, tintView, label, mascot) = FallbackHintPanel.make(
            message: message, width: Self.fallbackWidth, theme: currentTheme,
            target: self, action: #selector(dismissFallbackHint))
        hintPanel = hint
        hintTintView = tintView
        hintLabel = label
        hintMascot = mascot
    }

    func applyThemeToFallbackHint(_ theme: Theme) {
        hintTintView?.layer?.backgroundColor = theme.panelTintColor.cgColor
        hintLabel?.textColor = theme.foregroundColor
    }

    @objc func dismissFallbackHint() {
        hintDismissed = true
        guard let hint = hintPanel else { return }
        hintMascot?.stopAnimating()
        panel.removeChildWindow(hint)
        hint.orderOut(nil)
    }

    func updateFallbackHintVisibility() {
        guard !accessibilityTrusted, !hintDismissed, let hint = hintPanel else {
            if hintPanel?.isVisible == true { hintMascot?.stopAnimating() }
            hintPanel?.orderOut(nil)
            return
        }
        guard panel.isVisible, lastPresenceUntracked, !isExpanded else {
            if hint.isVisible { hintMascot?.stopAnimating() }
            hint.orderOut(nil)
            return
        }
        positionFallbackHint()
        if hint.parent !== panel {
            panel.addChildWindow(hint, ordered: .below)
        }
        let wasVisible = hint.isVisible
        hint.orderFront(nil)
        if !wasVisible {
            hintMascot?.startAnimating()
        }
    }

    func positionFallbackHint() {
        guard let hint = hintPanel else { return }
        let mainFrame = panel.frame
        hint.setFrameOrigin(
            NSPoint(x: mainFrame.minX, y: mainFrame.maxY - Self.fallbackHintOverlap))
    }
}
