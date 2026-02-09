// swift-tools-version: 5.4

import PackageDescription

let package = Package(
    name: "JXPhotoBrowser",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(
            name: "JXPhotoBrowser",
            targets: ["JXPhotoBrowser"]
        )
    ],
    targets: [
        .target(
            name: "JXPhotoBrowser",
            path: "Sources"
        )
    ]
)
