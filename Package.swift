// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Checkpoint",
	platforms: [
		.macOS(.v10_15),
		.iOS(.v13),
		.tvOS(.v13),
		.watchOS(.v6)
	],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Checkpoint",
            targets: ["Checkpoint"]),
    ],
	dependencies: [
		// 💧 A server-side Swift web framework.
		.package(url: "https://github.com/vapor/vapor.git", from: "4.115.0"),
		// Redis. Rate-Limit middleware
		.package(url: "https://github.com/vapor/redis.git", from: "4.13.0"),
		// OpenCombine for Linux compatibility when Combine isn't available
		.package(url: "https://github.com/OpenCombine/OpenCombine.git", from: "0.14.0"),
	],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Checkpoint",
			dependencies: [
				.product(name: "Vapor", package: "vapor"),
				.product(name: "Redis", package: "redis"),
				"OpenCombine",
				.product(name: "OpenCombineFoundation", package: "OpenCombine"),
				.product(name: "OpenCombineDispatch", package: "OpenCombine")
			]
		),
        .testTarget(
            name: "CheckpointTests",
            dependencies: [
				"Checkpoint",
				.product(name: "XCTVapor", package: "vapor")
			]
        ),
    ]
)
