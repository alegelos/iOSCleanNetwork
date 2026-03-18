// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "iOSCleanNetwork",
    platforms: [
        .iOS(.v17),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "iOSCleanNetwork",
            targets: ["iOSCleanNetwork"]
        ),
        .library(
            name: "iOSCleanNetworkTesting",
            targets: ["iOSCleanNetworkTesting"]
        )
    ],
    targets: [
        .target(
            name: "iOSCleanNetwork"
        ),
        .target(
            name: "iOSCleanNetworkTesting",
            dependencies: ["iOSCleanNetwork"]
        )
    ]
)
