// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "WeeklyTweetCronJob",
    platforms: [.macOS(.v12)],
    dependencies: [
        .package(url: "https://github.com/swift-server/swift-aws-lambda-runtime.git", from: "1.0.0-alpha.1"),
        .package(url: "https://github.com/swift-server/swift-aws-lambda-events.git", exact: "0.1.0")
    ],
    targets: [
        .executableTarget(
            name: "WeeklyTweetCronJob",
            dependencies: [
                .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
                .product(name: "AWSLambdaEvents", package: "swift-aws-lambda-events")
            ]
        )
    ]
)
