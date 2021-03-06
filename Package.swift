// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "VaporUploads",
    platforms: [
        .macOS(.v12)
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.55.4"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.4.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.2.6"),
        .package(url: "https://github.com/vapor/leaf.git", from: "4.0.0")
        //.package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "Vapor", package: "vapor"),
                // Leaf target dependency
                .product(name: "Leaf", package: "leaf")
               // .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .executableTarget(name: "Run", dependencies: [.target(name: "App")]),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
