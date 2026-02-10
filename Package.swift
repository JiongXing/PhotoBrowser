// swift-tools-version: 5.4

import PackageDescription

let package = Package(
    name: "JXPhotoBrowser",
    platforms: [
        .iOS(.v12)
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
            path: "Sources",
            resources: [
                .copy("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
