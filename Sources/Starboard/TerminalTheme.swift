import Cocoa
import SwiftTerm

enum TerminalTheme {
    static let fontSize: CGFloat = 11
    static let padding: CGFloat = 8
    static let cornerRadius: CGFloat = 12
    static let panelTintColor = NSColor(calibratedRed: 0.02, green: 0.035, blue: 0.06, alpha: 0.65)

    static let font: NSFont =
        preferredFontNames.lazy.compactMap { NSFont(name: $0, size: fontSize) }.first
        ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)

    private static let preferredFontNames = [
        "MesloLGS NF",
        "MesloLGS Nerd Font",
        "Hack Nerd Font",
        "FiraCode Nerd Font",
        "JetBrainsMono Nerd Font",
        "Menlo",
    ]

    static let ansiPalette: [Color] = [
        ansiColor(20, 24, 33),
        ansiColor(198, 74, 90),
        ansiColor(79, 157, 105),
        ansiColor(196, 154, 62),
        ansiColor(58, 124, 165),
        ansiColor(133, 110, 168),
        ansiColor(69, 156, 156),
        ansiColor(196, 190, 172),
        ansiColor(75, 87, 99),
        ansiColor(222, 102, 118),
        ansiColor(111, 191, 135),
        ansiColor(224, 186, 105),
        ansiColor(95, 168, 211),
        ansiColor(169, 143, 201),
        ansiColor(114, 214, 207),
        ansiColor(230, 224, 208),
    ]
}

private func ansiColor(_ red: UInt16, _ green: UInt16, _ blue: UInt16) -> Color {
    Color(red: red * 257, green: green * 257, blue: blue * 257)
}
