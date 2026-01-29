// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ThreadSafeExamplePackage",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "ThreadSafeExampleDeps",
            type: .static,
            targets: ["Default"]
        )
    ],
    dependencies: [
        .package(name: "ThreadSafe", path: "../../"),
        .package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", .upToNextMinor(from: "0.63.2"))
    ],
    targets: [
        .target(
            name: "Default",
            dependencies: [
                "ThreadSafe",
                .target(name: "Debug")
            ]
        ),
        .target(
            name: "Debug",
            dependencies: [],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ],
            plugins: [
                .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")
            ]
        )
    ]
)
