import PackageDescription

let package = Package(
    name: "MapboxDemo2-iOS",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "MapboxDemo2-iOS",
            targets: ["MapboxDemo2-iOS"]),
    ],
    dependencies: [
        .package(url: "https://github.com/mapbox/mapbox-maps-ios.git", from: "11.0.0")
    ],
    targets: [
        .target(
            name: "MapboxDemo2-iOS",
            dependencies: [
                .product(name: "MapboxMaps", package: "mapbox-maps-ios")
            ]),
    ]
)
