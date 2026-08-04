// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Starboard",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Starboard",
            path: "Sources/Starboard"
        )
    ]
)
