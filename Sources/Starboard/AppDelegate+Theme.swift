import Cocoa

extension AppDelegate {
    func applyTheme(_ theme: Theme, persist: Bool) {
        currentTheme = theme
        tintView.layer?.backgroundColor = theme.panelTintColor.cgColor
        terminalView.nativeForegroundColor = theme.foregroundColor
        terminalView.installColors(theme.ansiPalette)
        if persist {
            UserDefaults.standard.set(theme.id, forKey: "themeID")
        }
    }

    @objc func toggleThemePicker(_ sender: Any?) {
        if let picker = themePickerView {
            picker.removeFromSuperview()
            themePickerView = nil
            panel.makeFirstResponder(terminalView)
            return
        }
        guard let container = panel.contentView else { return }

        let picker = ThemePickerView(themes: Theme.all, selectedID: currentTheme.id)
        picker.frame.origin = NSPoint(
            x: container.bounds.maxX - picker.frame.width - 10,
            y: container.bounds.maxY - picker.frame.height - 10)
        picker.onCommit = { [weak self] theme in
            self?.applyTheme(theme, persist: true)
            self?.toggleThemePicker(nil)
        }
        picker.onCancel = { [weak self] in self?.toggleThemePicker(nil) }

        container.addSubview(picker)
        themePickerView = picker
        panel.makeFirstResponder(picker)
    }
}
