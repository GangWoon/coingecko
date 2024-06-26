// swift-tools-version: 5.10
import PackageDescription

let package = Package(
  name: "ViewHelper",
  platforms: [.iOS(.v15)],
  products: [
    .library(
      name: "ViewHelper",
      targets: ["ViewHelper"]
    ),
    .library(
      name: "ViewControllerHelper",
      targets: ["ViewControllerHelper"]
    ),
  ],
  targets: [
    .target(name: "ViewHelper"),
    .target(name: "ViewControllerHelper")
  ]
)
