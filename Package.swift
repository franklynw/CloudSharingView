// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CloudSharingView",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "CloudSharingView",
            targets: ["CloudSharingView"]),
    ],
    dependencies: [
        .package(name: "TopAlert", url: "https://github.com/franklynw/TopAlert.git", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "CloudSharingView",
            dependencies: ["TopAlert"],
            resources: [.process("Resources")]),
        .testTarget(
            name: "CloudSharingViewTests",
            dependencies: ["CloudSharingView"]),
    ]
)
