import ApplicationServices
import Cocoa

extension AppDelegate {
    static let dockPreferencesDomain = "com.apple.dock" as CFString

    func dockOrientation() -> String {
        CFPreferencesAppSynchronize(Self.dockPreferencesDomain)
        return
            (CFPreferencesCopyAppValue("orientation" as CFString, Self.dockPreferencesDomain)
            as? String) ?? "bottom"
    }

    func dockAutoHides() -> Bool {
        (CFPreferencesCopyAppValue("autohide" as CFString, Self.dockPreferencesDomain) as? Bool)
            ?? false
    }

    func dockIconTrayFrame(flippedAgainst mainScreen: NSScreen) -> NSRect? {
        guard let dockApp = dockApplication() else { return nil }

        let axApp = AXUIElementCreateApplication(dockApp.processIdentifier)

        var childrenRef: AnyObject?
        guard
            AXUIElementCopyAttributeValue(axApp, kAXChildrenAttribute as CFString, &childrenRef)
                == .success,
            let children = childrenRef as? [AXUIElement]
        else {
            return nil
        }

        guard let list = children.first(where: { axRole(of: $0) == (kAXListRole as String) })
        else {
            return nil
        }

        guard let position = axPoint(list, kAXPositionAttribute as CFString),
            let size = axSize(list, kAXSizeAttribute as CFString)
        else {
            return nil
        }

        let flippedY = mainScreen.frame.maxY - position.y - size.height
        let frame = NSRect(x: position.x, y: flippedY, width: size.width, height: size.height)
        debugLog("tray", "ax position \(position) size \(size) -> \(frame)")
        return frame
    }

    private func axRole(of element: AXUIElement) -> String? {
        var roleRef: AnyObject?
        guard
            AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef)
                == .success
        else {
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
