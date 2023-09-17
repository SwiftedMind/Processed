// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "Processed",
  platforms: [.iOS(.v15), .watchOS(.v8), .macOS(.v10_13), .tvOS(.v15), .visionOS(.v1)],
  products: [
    .library(
      name: "Processed",
      targets: ["Processed"]),
  ],
  targets: [
    .target(
      name: "Processed"),
    .testTarget(
      name: "ProcessedTests",
      dependencies: ["Processed"]),
  ]
)
