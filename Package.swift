// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "StandUpReminder",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(
            name: "StandUpReminder",
            targets: ["StandUpReminder"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "StandUpReminder"
        ),
    ]
)
