import Cocoa
import CoreGraphics

extension AppDelegate {
    func mainDisplayScreen() -> NSScreen? {
        screen(for: CGMainDisplayID())
    }

    func screen(for displayID: CGDirectDisplayID) -> NSScreen? {
        NSScreen.screens.first { self.displayID(of: $0) == displayID }
    }

    func displayID(of screen: NSScreen) -> CGDirectDisplayID? {
        (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?
            .uint32Value
    }

    func screenHosting(_ rect: NSRect) -> NSScreen? {
        let centre = NSPoint(x: rect.midX, y: rect.midY)
        if let hit = NSScreen.screens.first(where: { $0.frame.contains(centre) }) { return hit }
        return screenWithGreatestIntersection(with: rect)
    }

    func screenWithGreatestIntersection(with rect: NSRect) -> NSScreen? {
        var best: NSScreen?
        var bestArea: CGFloat = 0
        for screen in NSScreen.screens {
            let overlap = screen.frame.intersection(rect)
            guard !overlap.isNull else { continue }
            let area = overlap.width * overlap.height
            if area > bestArea {
                bestArea = area
                best = screen
            }
        }
        return best
    }

    func dockWindowHostScreen() -> NSScreen? {
        guard let dockApp = dockApplication(), let mainScreen = mainDisplayScreen() else {
            return nil
        }
        guard
            let windows = CGWindowListCopyWindowInfo([.optionAll], kCGNullWindowID)
                as? [[String: Any]]
        else {
            return nil
        }

        let matches = windows.filter {
            ($0[kCGWindowOwnerPID as String] as? pid_t) == dockApp.processIdentifier
                && ($0[kCGWindowLayer as String] as? Int) == 20
        }
        guard matches.count == 1,
            let boundsValue = matches[0][kCGWindowBounds as String] as? NSDictionary,
            let bounds = CGRect(dictionaryRepresentation: boundsValue)
        else {
            debugLog(
                "dockwindow",
                "expected exactly one layer-20 Dock window, got \(matches.count); "
                    + "falling back to the main display")
            return nil
        }

        let appKitY = mainScreen.frame.maxY - (bounds.origin.y + bounds.height)
        let frame = NSRect(
            x: bounds.origin.x, y: appKitY, width: bounds.width, height: bounds.height)
        debugLog("dockwindow", "bounds \(bounds) -> \(frame)")
        return screenWithGreatestIntersection(with: frame)
    }

    func dockApplication() -> NSRunningApplication? {
        NSWorkspace.shared.runningApplications.first {
            $0.bundleIdentifier == "com.apple.dock"
        }
    }

    func describe(_ displayID: CGDirectDisplayID?) -> String {
        guard let displayID else { return "none" }
        guard let screen = screen(for: displayID) else { return "\(displayID) (gone)" }
        return "\(displayID) \(screen.frame)"
    }
}
