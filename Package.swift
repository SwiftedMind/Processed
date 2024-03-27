// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "Processed",
  platforms: [.iOS(.v15), .watchOS(.v8), .macOS(.v13), .tvOS(.v15)],
  products: [
    .library(
      name: "Processed",
      targets: ["Processed"]
    ),
    .library(
      name: "ProcessedUtility",
      targets: ["Processed", "ProcessedUtility"]
    ),
  ],
  targets: [
    .target(
      name: "Processed"
    ),
    .target(name: "ProcessedUtility", dependencies: ["Processed"]),
    .testTarget(
      name: "ProcessedTests",
      dependencies: ["Processed"]
    ),
  ]
)
