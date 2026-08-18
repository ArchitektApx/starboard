import Cocoa
import SwiftTerm

struct Theme {
    let id: String
    let name: String
    let panelTintColor: NSColor
    let foregroundColor: NSColor
    let ansiPalette: [Color]
}

extension Theme {
    static let all: [Theme] = [.nebula, .green, .dracula, .nord]

    static let `default` = Theme.nebula

    static func theme(id: String) -> Theme {
        all.first { $0.id == id } ?? .default
    }

    static let nebula = Theme(
        id: "nebula",
        name: "Nebula",
        panelTintColor: nsColor(5, 9, 15, alpha: 0.65),
        foregroundColor: .labelColor,
        ansiPalette: [
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
    )

    static let green = Theme(
        id: "green",
        name: "Terminal Green",
        panelTintColor: nsColor(0, 8, 0, alpha: 0.82),
        foregroundColor: nsColor(70, 255, 120),
        ansiPalette: [
            ansiColor(0, 0, 0),
            ansiColor(0, 110, 40),
            ansiColor(0, 170, 60),
            ansiColor(40, 190, 70),
            ansiColor(0, 140, 90),
            ansiColor(60, 170, 110),
            ansiColor(0, 190, 150),
            ansiColor(170, 220, 170),
            ansiColor(50, 80, 50),
            ansiColor(40, 220, 80),
            ansiColor(80, 255, 120),
            ansiColor(140, 255, 140),
            ansiColor(60, 220, 160),
            ansiColor(120, 255, 180),
            ansiColor(100, 255, 200),
            ansiColor(210, 255, 210),
        ]
    )

    static let dracula = Theme(
        id: "dracula",
        name: "Dracula",
        panelTintColor: nsColor(40, 42, 54, alpha: 0.78),
        foregroundColor: nsColor(248, 248, 242),
        ansiPalette: [
            ansiColor(33, 34, 44),
            ansiColor(255, 85, 85),
            ansiColor(80, 250, 123),
            ansiColor(241, 250, 140),
            ansiColor(189, 147, 249),
            ansiColor(255, 121, 198),
            ansiColor(139, 233, 253),
            ansiColor(248, 248, 242),
            ansiColor(98, 114, 164),
            ansiColor(255, 110, 110),
            ansiColor(105, 255, 148),
            ansiColor(255, 255, 165),
            ansiColor(214, 172, 255),
            ansiColor(255, 146, 223),
            ansiColor(164, 255, 255),
            ansiColor(255, 255, 255),
        ]
    )

    static let nord = Theme(
        id: "nord",
        name: "Nord",
        panelTintColor: nsColor(46, 52, 64, alpha: 0.78),
        foregroundColor: nsColor(216, 222, 233),
        ansiPalette: [
            ansiColor(59, 66, 82),
            ansiColor(191, 97, 106),
            ansiColor(163, 190, 140),
            ansiColor(235, 203, 139),
            ansiColor(129, 161, 193),
            ansiColor(180, 142, 173),
            ansiColor(136, 192, 208),
            ansiColor(229, 233, 240),
            ansiColor(76, 86, 106),
            ansiColor(191, 97, 106),
            ansiColor(163, 190, 140),
            ansiColor(235, 203, 139),
            ansiColor(129, 161, 193),
            ansiColor(180, 142, 173),
            ansiColor(143, 188, 187),
            ansiColor(236, 239, 244),
        ]
    )
}

private func ansiColor(_ red: UInt16, _ green: UInt16, _ blue: UInt16) -> Color {
    Color(red: red * 257, green: green * 257, blue: blue * 257)
}

private func nsColor(_ red: Int, _ green: Int, _ blue: Int, alpha: CGFloat = 1) -> NSColor {
    NSColor(
        calibratedRed: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255,
        alpha: alpha)
}
