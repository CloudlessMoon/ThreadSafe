// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "ThreadSafe",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "ThreadSafe",
            targets: ["ThreadSafe"]
        )
    ],
    targets: [
        .target(
            name: "ThreadSafe",
            path: "Sources"
        )
    ],
    swiftLanguageModes: [.version("5.1")]
)
