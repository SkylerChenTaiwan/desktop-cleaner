// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "DesktopCleaner",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "DesktopCleanerLib",
            targets: ["DesktopCleanerLib"]
        )
    ],
    targets: [
        .target(
            name: "DesktopCleanerLib",
            path: "Sources/DesktopCleanerLib"
        ),
        .executableTarget(
            name: "DesktopCleaner",
            dependencies: ["DesktopCleanerLib"],
            path: "Sources/DesktopCleaner"
        ),
        .executableTarget(
            name: "TestRunner",
            dependencies: ["DesktopCleanerLib"],
            path: "Sources/TestRunner"
        )
    ]
)
