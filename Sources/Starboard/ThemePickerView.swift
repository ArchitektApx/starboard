import Cocoa

final class ThemePickerView: NSView {
    private let themes: [Theme]
    private var selectedIndex: Int
    private let rowHeight: CGFloat = 22

    var onCommit: ((Theme) -> Void)?
    var onCancel: (() -> Void)?

    init(themes: [Theme], selectedID: String) {
        self.themes = themes
        self.selectedIndex = themes.firstIndex { $0.id == selectedID } ?? 0
        let height = CGFloat(themes.count) * rowHeight + 8
        super.init(frame: NSRect(x: 0, y: 0, width: 170, height: height))
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.withAlphaComponent(0.6).cgColor
        layer?.cornerRadius = 8
        layer?.masksToBounds = true
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.white.withAlphaComponent(0.15).cgColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool { true }
    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        for (index, theme) in themes.enumerated() {
            let rowRect = NSRect(
                x: 4, y: 4 + CGFloat(index) * rowHeight, width: bounds.width - 8,
                height: rowHeight)
            if index == selectedIndex {
                NSColor.white.withAlphaComponent(0.2).setFill()
                NSBezierPath(roundedRect: rowRect, xRadius: 5, yRadius: 5).fill()
            }
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: NSColor.white,
                .font: NSFont.systemFont(
                    ofSize: 12, weight: index == selectedIndex ? .semibold : .regular),
            ]
            let textSize = theme.name.size(withAttributes: attributes)
            let origin = NSPoint(
                x: rowRect.minX + 10, y: rowRect.minY + (rowHeight - textSize.height) / 2)
            theme.name.draw(at: origin, withAttributes: attributes)
        }
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 126: move(-1)
        case 125: move(1)
        case 36, 76: onCommit?(themes[selectedIndex])
        case 53: onCancel?()
        default: break
        }
    }

    private func move(_ delta: Int) {
        selectedIndex = (selectedIndex + delta + themes.count) % themes.count
        needsDisplay = true
    }
}
