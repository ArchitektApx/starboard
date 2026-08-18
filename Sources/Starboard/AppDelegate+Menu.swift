import Cocoa

extension AppDelegate {
    func setUpMainMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu
        appMenu.addItem(
            withTitle: "Toggle Expanded", action: #selector(toggleExpanded(_:)), keyEquivalent: "e"
        )
        appMenu.addItem(
            withTitle: "Quit Starboard", action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q")

        let editMenuItem = NSMenuItem()
        mainMenu.addItem(editMenuItem)
        let editMenu = NSMenu(title: "Edit")
        editMenuItem.submenu = editMenu
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(
            withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(
            withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

        let themeMenuItem = NSMenuItem()
        mainMenu.addItem(themeMenuItem)
        let themeMenu = NSMenu(title: "Theme")
        themeMenuItem.submenu = themeMenu
        for theme in Theme.all {
            let item = themeMenu.addItem(
                withTitle: theme.name, action: #selector(selectTheme(_:)), keyEquivalent: "")
            item.representedObject = theme.id
            item.state = theme.id == currentTheme.id ? .on : .off
        }

        NSApp.mainMenu = mainMenu
    }

    @objc func toggleExpanded(_ sender: Any?) {
        refreshCoarseCaches()
        let presence = resolveDockPresence()

        if isExpanded {
            isExpanded = false
            expansionScreenID = nil
            applyFrame(collapseTarget(for: presence))
        } else {
            isExpanded = true
            let screen = expansionScreen(fallingBackTo: presence?.host)
            expansionScreenID = screen.flatMap(displayID(of:))
            if let screen {
                applyFrame(expandedFrame(on: screen))
            }
        }
        debugLog("expand", "isExpanded=\(isExpanded) screen=\(describe(expansionScreenID))")
    }
}
