// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "ChessUI",
  platforms: [
    .iOS(.v17),
    .macOS(.v14)
  ],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "ChessUI",
      targets: ["ChessUI"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/iliaskarim/ChessCore.git", branch: "develop"),
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.12.0")
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "ChessUI",
      dependencies: [
        "ChessCore"
      ],
      resources: [
        .process("Assets.xcassets")
      ]
    ),
    .testTarget(
      name: "ChessUITests",
      dependencies: [
        "ChessUI",
        .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
      ]
    )
  ]
)
