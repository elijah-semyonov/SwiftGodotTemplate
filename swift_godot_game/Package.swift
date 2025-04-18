// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftGodotGame",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftGodotGame",
            type: .dynamic,
            targets: ["SwiftGodotGame"]),
    ],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftGodot", branch: "main")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftGodotGame",
            dependencies: [
                .product(name: "SwiftGodot", package: "swiftgodot")
            ],
            plugins: [                
                .plugin(name: "EntryPointGeneratorPlugin", package: "swiftgodot")
            ]
        ),
        .testTarget(
            name: "SwiftGodotGameTests",
            dependencies: ["SwiftGodotGame"]
        ),
    ]
)
