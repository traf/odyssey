// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Odyssey",
    platforms: [
        .macOS(.v26)
    ],
    targets: [
        .executableTarget(
            name: "Odyssey",
            path: "Sources/Odyssey",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
