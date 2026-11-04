// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        .macOS("12.0")
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "flutter_local_notifications", path: "../.packages/flutter_local_notifications-22.3.3"),
        .package(name: "geolocator_apple", path: "../.packages/geolocator_apple-2.3.14"),
        .package(name: "local_auth_darwin", path: "../.packages/local_auth_darwin-2.0.3"),
        .package(name: "package_info_plus", path: "../.packages/package_info_plus-10.2.2"),
        .package(name: "shared_preferences_foundation", path: "../.packages/shared_preferences_foundation-2.5.6"),
        .package(name: "url_launcher_macos", path: "../.packages/url_launcher_macos-3.2.5"),
        .package(name: "FlutterFramework", path: "../.packages/FlutterFramework")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "flutter-local-notifications", package: "flutter_local_notifications"),
                .product(name: "geolocator-apple", package: "geolocator_apple"),
                .product(name: "local-auth-darwin", package: "local_auth_darwin"),
                .product(name: "package-info-plus", package: "package_info_plus"),
                .product(name: "shared-preferences-foundation", package: "shared_preferences_foundation"),
                .product(name: "url-launcher-macos", package: "url_launcher_macos"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
