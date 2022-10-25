// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "SugiKit",
    platforms: [
        .macOS(.v10_10),
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "SugiKit",
            targets: ["SugiKit"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/coniferprod/SyxPack",
            from: "0.7.1"
        ),
    ],
    targets: [
        .target(
            name: "SugiKit",
            dependencies: ["SyxPack"]
        ),
        .testTarget(
            name: "SugiKitTests",
            dependencies: ["SugiKit", "SyxPack"],
            resources: [
                .copy("Resources")
            ]
        ),
    ]
)

// https://developer.apple.com/documentation/swift_packages/bundling_resources_with_a_swift_package
