// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SwiftUIToasts",
    platforms: [
        .iOS(.v18),
        .tvOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(name: "SwiftUIToasts", targets: ["SwiftUIToasts"]),
    ],
    targets: [
        .target(name: "SwiftUIToasts"),
        .testTarget(
            name: "SwiftUIToastsTests",
            dependencies: ["SwiftUIToasts"]
        ),
    ]
)
