import Cocoa

enum TerminalTheme {
    static let fontSize: CGFloat = 11
    static let padding: CGFloat = 8
    static let cornerRadius: CGFloat = 12

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
}
