// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "howto",
    platforms: [.macOS(.v10_15)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        .package(url: "https://github.com/swift-server/async-http-client.git", exact: "1.22.2"),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.7.5"),
    ],
    targets: [
        .executableTarget(
            name: "howto",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                "SwiftSoup",
            ]
        ),
        .testTarget(
            name: "howtoTests",
            dependencies: [
                "howto",
            ]
        ),
    ]
)
