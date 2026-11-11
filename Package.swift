// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "support",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/evalship-hq/tinyeval-swift", from: "0.11.0"),
    ],
    targets: [
        .target(name: "Support"),
        .executableTarget(name: "evalworker", dependencies: [
            "Support",
            .product(name: "Tinyeval", package: "tinyeval-swift"),
        ]),
    ]
)
