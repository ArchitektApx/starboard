import Foundation

extension AppDelegate {
    static let debugEnabled =
        ProcessInfo.processInfo.environment["STARBOARD_DEBUG"] == "1"
    static let debugEventChannels: Set<String> = [
        "visibility", "expand", "screens", "timer",
    ]

    func debugLog(_ channel: String, _ message: String) {
        guard Self.debugEnabled else { return }
        if !Self.debugEventChannels.contains(channel) {
            guard lastDebugLine[channel] != message else { return }
            lastDebugLine[channel] = message
        }
        guard let data = "[starboard.\(channel)] \(message)\n".data(using: .utf8) else { return }
        FileHandle.standardError.write(data)
    }
}
