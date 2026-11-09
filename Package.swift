// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MaxNitsControl",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "MaxNitsControl", path: "Sources/MaxNitsControl")
    ]
)
