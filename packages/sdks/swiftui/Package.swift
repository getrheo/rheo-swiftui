// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "RheoSwiftUI",
  platforms: [
    .iOS(.v16),
    .macOS(.v10_15),
  ],
  products: [
    .library(name: "RheoSwiftUI", targets: ["RheoSwiftUI", "RheoSwiftUILottie"]),
    .library(name: "RheoSwiftUIRevenueCat", targets: ["RheoSwiftUIRevenueCat"]),
    .library(name: "RheoSwiftUIAppsFlyer", targets: ["RheoSwiftUIAppsFlyer"]),
  ],
  dependencies: [
    .package(url: "https://github.com/airbnb/lottie-ios.git", from: "4.4.0"),
  ],
  targets: [
    .target(
      name: "RheoSwiftUILottie",
      dependencies: [
        .product(name: "Lottie", package: "lottie-ios"),
      ],
    ),
    .target(
      name: "RheoSwiftUI",
      dependencies: ["RheoSwiftUILottie"],
      resources: [
        .process("Resources"),
      ],
    ),
    .target(
      name: "RheoSwiftUIRevenueCat",
      dependencies: ["RheoSwiftUI"],
    ),
    .target(
      name: "RheoSwiftUIAppsFlyer",
      dependencies: ["RheoSwiftUI"],
    ),
    .testTarget(
      name: "RheoSwiftUITests",
      dependencies: ["RheoSwiftUI"],
      resources: [
        .process("Fixtures"),
      ],
    ),
    .testTarget(
      name: "RheoSwiftUIAppsFlyerTests",
      dependencies: ["RheoSwiftUIAppsFlyer"],
    ),
  ],
)
