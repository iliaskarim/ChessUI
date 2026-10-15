// swift-tools-version: 5.10
import PackageDescription

let package = Package(
  name: "ChessUI",
  platforms: [
    .iOS(.v17),
    .macOS(.v14)
  ],
  products: [
    .library(
      name: "ChessUI",
      targets: ["ChessUI"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/iliaskarim/ChessCore.git", branch: "master"),
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.12.0")
  ],
  targets: [
    .target(
      name: "ChessUI",
      dependencies: [
        "ChessCore"
      ],
      resources: [
        .process("Assets.xcassets"),
        .copy("Sounds")
      ]
    ),
    .testTarget(
      name: "ChessUITests",
      dependencies: [
        "ChessCore",
        "ChessUI",
        .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
      ]
    )
  ]
)
