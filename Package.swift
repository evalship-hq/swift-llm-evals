// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "support",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "Support"),
        .executableTarget(name: "evalworker", dependencies: ["Support"]),
    ]
)
