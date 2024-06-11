// swift-tools-version: 6.0
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
    .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.3")
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
        "ApiClientLive",
        "RecentSearchesClientLive",
        "CombineExt"
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
      name: "ApiClient",
      dependencies: [
        .product(name: "HTTPClientLive", package: "HTTPClient")
      ]
    ),
    .target(
      name: "ApiClientLive",
      dependencies: [
        "ApiClient",
        .product(
          name: "HTTPClientLive",
          package: "HTTPClient"
        )
      ],
      swiftSettings: [
        .enableExperimentalFeature("StrictConcurrency")
      ]
    ),
    .target(
      name: "RecentSearchesClient",
      dependencies: [
        .product(name: "SQLite", package: "sqlite.swift")
      ]
    ),
    .target(
      name: "RecentSearchesClientLive",
      dependencies: [
        "RecentSearchesClient"
      ]
    ),
    .target(name: "CombineExt"),
    .testTarget(
      name: "SearchFeatureTests",
      dependencies: ["SearchFeature"]),
  ],
  swiftLanguageVersions: [.v6]
)
