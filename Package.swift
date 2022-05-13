// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Calendar",
    defaultLocalization: "ru",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "Calendar",
            targets: ["Calendar"]
        ),
        .library(
            name: "CalendarEventKit",
            targets: ["CalendarEventKit"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/ReactiveCocoa/ReactiveSwift.git",
            from: .init(7, 0, 0)
        ),
        .package(
            url: "https://github.com/ReactiveCocoa/ReactiveCocoa.git",
            from: .init(12, 0, 0)
        ),
        .package(
            url: "https://github.com/bteapot/InfiniteScrollView.git",
            from: .init(1, 0, 0)
        ),
    ],
    targets: [
        .target(
            name: "Calendar",
            dependencies: [
                "ReactiveSwift",
                "ReactiveCocoa",
                "InfiniteScrollView",
            ]
        ),
        .target(
            name: "CalendarEventKit",
            dependencies: [
                "Calendar",
            ]
        ),
    ]
)
