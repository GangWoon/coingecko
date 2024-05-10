// swift-tools-version: 5.10
import PackageDescription

let package = Package(
  name: "HTTPInterface",
  platforms: [.iOS(.v13)],
  products: [
    .library(
      name: "HTTPInterface",
      targets: ["HTTPInterface"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-http-types.git", from: "1.0.3")
  ],
  targets: [
    .target(
      name: "HTTPInterface",
      dependencies: [
        .product(name: "HTTPTypes", package: "swift-http-types")
      ]
    )
  ]
)
