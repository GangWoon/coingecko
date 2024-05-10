// swift-tools-version: 5.10
import PackageDescription

let package = Package(
  name: "AppPackage",
  products: [
    .library(
      name: "AppFeature",
      targets: ["AppFeature"]),
  ],
//  dependencies: [
//    .package(path: "../HTTPInterface")
//  ],
  targets: [
    .target(
      name: "AppFeature"
    ),
    .testTarget(
      name: "AppPackageTests",
      dependencies: ["AppFeature"]),
  ]
)
