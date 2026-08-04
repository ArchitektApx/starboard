// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Starboard",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftTerm", from: "1.2.0")
    ],
    targets: [
        .executableTarget(
            name: "Starboard",
            dependencies: ["SwiftTerm"],
            path: "Sources/Starboard"
        )
    ]
)
