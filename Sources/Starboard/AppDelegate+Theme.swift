import Cocoa

extension AppDelegate {
    @objc func selectTheme(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        let theme = Theme.theme(id: id)
        currentTheme = theme
        UserDefaults.standard.set(theme.id, forKey: "themeID")

        tintView.layer?.backgroundColor = theme.panelTintColor.cgColor
        terminalView.nativeForegroundColor = theme.foregroundColor
        terminalView.installColors(theme.ansiPalette)

        sender.menu?.items.forEach { $0.state = .off }
        sender.state = .on
    }
}
