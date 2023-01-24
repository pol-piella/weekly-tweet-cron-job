// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "WeeklyTweetCronJob",
    platforms: [.macOS(.v12)],
    dependencies: [
    ],
    targets: [
        .executableTarget(
            name: "WeeklyTweetCronJob",
            dependencies: []
        )
    ]
)
