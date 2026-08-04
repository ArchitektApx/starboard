import Cocoa

/// Borderless panels don't become key by default, which would leave the
/// text field unable to receive keystrokes. `.nonactivatingPanel` keeps
/// the panel from stealing focus from whatever app the user is in.
final class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
