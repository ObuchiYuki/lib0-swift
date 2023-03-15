// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "lib0-swift",
    products: [
        .library(name: "lib0", targets: ["lib0"])
    ],
    dependencies: [],
    targets: [
        .target(name: "lib0", dependencies: []),
        .testTarget(name: "lib0-Tests", dependencies: ["lib0"])
    ]
)
