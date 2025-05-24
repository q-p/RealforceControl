// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "RealforceControl",
  platforms: [.macOS(.v15)],
  products: [
    .library(
      name: "RealforceControl",
      targets: ["RealforceControl"],
    ),
    .executable(
      name: "rfctrl",
      targets: ["rfctrl"],
    ),
  ],
  targets: [
    .target(
      name: "RealforceControl",
    ),
    .executableTarget(
      name: "rfctrl",
      dependencies: ["RealforceControl"],
    ),
  ]
)
