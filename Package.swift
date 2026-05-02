// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WelcomeView",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "WelcomeView",
            targets: ["WelcomeView"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "WelcomeView",
            dependencies: [],
            path: "Sources/WelcomeView",
            resources: []
        )
    ]
)
