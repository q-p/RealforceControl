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
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMajor(from: "1.5.0")),
  ],
  targets: [
    .target(
      name: "RealforceControl",
    ),
    .executableTarget(
      name: "rfctrl",
      dependencies: ["RealforceControl", .product(name: "ArgumentParser", package: "swift-argument-parser")],
    ),
  ],
)
