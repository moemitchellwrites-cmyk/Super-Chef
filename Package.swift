// swift-tools-version: 5.9
import PackageDescription

// Pantry (working title): the cooking game. This package is the scoring engine
// and the bundled cuisine content. It has no dependencies and makes no network
// calls, so the free game scores offline. The iOS app target comes in step 2
// of the build order (see docs/backlog.md).
let package = Package(
    name: "Pantry",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "PantryScoring", targets: ["PantryScoring"]),
    ],
    targets: [
        .target(
            name: "PantryScoring",
            path: "Sources/PantryScoring",
            resources: [.copy("Resources/sichuan")]
        ),
        .testTarget(
            name: "PantryScoringTests",
            dependencies: ["PantryScoring"],
            path: "Tests/PantryScoringTests",
            resources: [.copy("Fixtures")]
        ),
    ]
)
