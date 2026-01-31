// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Macxelio",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "Macxelio",
            targets: ["Macxelio"]
        )
    ],
    targets: [
        .executableTarget(
            name: "Macxelio",
            path: "Sources",
            resources: [
                .process("../Assets.xcassets")
            ]
        )
    ]
)
