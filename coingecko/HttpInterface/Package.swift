// swift-tools-version: 5.10
import PackageDescription

let package = Package(
  name: "HttpInterface",
  platforms: [.iOS(.v13)],
  products: [
    .library(
      name: "HttpInterface",
      targets: ["HttpInterface"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-http-types.git", from: "1.0.3")
  ],
  targets: [
    .target(
      name: "HttpInterface",
      dependencies: [
        .product(name: "HTTPTypes", package: "swift-http-types")
      ]
    )
  ]
)
