// swift-tools-version: 5.10
import PackageDescription

let package = Package(
  name: "HTTPClient",
  platforms: [.iOS(.v13)],
  products: [
    .library(
      name: "HTTPClient",
      targets: ["HTTPClient"]
    ),
    .library(
      name: "HTTPClientLive",
      targets: ["HTTPClientLive"]
    ),
  ],
  targets: [
    .target(name: "HTTPClient"),
    .target(
      name: "HTTPClientLive",
      dependencies: ["HTTPClient"]
    )
  ]
)

for target in package.targets {
  var settings = target.swiftSettings ?? []
  settings.append(.enableExperimentalFeature("StrictConcurrency"))
  target.swiftSettings = settings
}
