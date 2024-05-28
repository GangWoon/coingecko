// swift-tools-version: 5.10
import PackageDescription

let package = Package(
  name: "AppPackage",
  platforms: [.iOS(.v15)],
  products: [
    .library(
      name: "AppFeature",
      targets: ["AppFeature"]),
  ],
  dependencies: [
    .package(path: "./HTTPClient"),
    .package(path: "./ViewHelper"),
  ],
  targets: [
    .target(
      name: "AppFeature",
      dependencies: [
        "SearchFeature",
        "SearchFeatureView"
      ]
    ),
    .target(
      name: "SearchFeature",
      dependencies: [
        "APIClient"
      ]
    ),
    .target(
      name: "SearchFeatureView",
      dependencies: [
        "SearchFeature",
        "CombineExt",
        .product(name: "ViewHelper", package: "ViewHelper"),
        .product(name: "ViewControllerHelper", package: "ViewHelper")
      ]
    ),
    .target(
      name: "APIClient",
      dependencies: [
        .product(name: "HTTPClientLive", package: "HTTPClient")
      ],
      swiftSettings: [
        .enableExperimentalFeature("StrictConcurrency")
      ]
    ),
    .target(name: "CombineExt"),
    .testTarget(
      name: "AppPackageTests",
      dependencies: ["AppFeature"]),
  ]
)
