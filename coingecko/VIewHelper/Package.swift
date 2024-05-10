// swift-tools-version: 5.10
import PackageDescription

let package = Package(
  name: "VIewHelper",
  platforms: [.iOS(.v15)],
  products: [
    .library(
      name: "VIewHelper",
      targets: ["VIewHelper"]),
  ],
  targets: [
    .target(
      name: "VIewHelper"),
  ]
)
