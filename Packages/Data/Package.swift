// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Data",
    platforms: [
        .iOS(.v18),
        .watchOS(.v11)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Data",
            targets: ["Data"]),
    ],
    dependencies: [
        .package(path: "../Domain")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Data",
            dependencies: ["Domain"],
            resources: [
                .process("Persistence/CoreData/BulkTrack.xcdatamodeld")
            ]
        ),
        .testTarget(
            name: "DataTests",
            dependencies: ["Data"]
        ),
    ]
)
