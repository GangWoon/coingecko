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
    .package(path: "../HTTPInterface"),
    .package(path: "../ViewHelper")
  ],
  targets: [
    .target(
      name: "AppFeature",
      dependencies: [
        "SearchFeature"
      ]
    ),
    .target(
      name: "SearchFeature",
      dependencies: [
        "CombineExt",
        "HTTPInterface",
        "ViewHelper"
      ]
    ),
    .target(name: "CombineExt"),
    .testTarget(
      name: "AppPackageTests",
      dependencies: ["AppFeature"]),
  ]
)
