// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "ShortcutKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "ShortcutKit", targets: ["ShortcutKit"]),
    ],
    targets: [
        .target(name: "ShortcutKit"),
        .testTarget(name: "ShortcutKitTests", dependencies: ["ShortcutKit"]),
    ]
)
