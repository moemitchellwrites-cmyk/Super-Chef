// swift-tools-version: 5.9
import PackageDescription

// Pantry (working title): the cooking game. This package holds the scoring
// engine, the bundled cuisine content, the round logic and the round screen.
// It has no dependencies and makes no network calls, so the free game scores
// offline. The iOS app (App/Pantry.xcodeproj) is a thin shell around PantryUI.
let package = Package(
    name: "Pantry",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "PantryScoring", targets: ["PantryScoring"]),
        .library(name: "PantryGame", targets: ["PantryGame"]),
        .library(name: "PantryUI", targets: ["PantryUI"]),
    ],
    targets: [
        .target(
            name: "PantryScoring",
            path: "Sources/PantryScoring",
            resources: [.copy("Resources/sichuan")]
        ),
        // The round at the vessel as plain values: stepper ladder, round state,
        // sound cues and the placeholder synth. No UI frameworks, so it is tested here.
        .target(
            name: "PantryGame",
            dependencies: ["PantryScoring"],
            path: "Sources/PantryGame"
        ),
        // The screen itself: SwiftUI round view, SpriteKit vessel scene, AVAudioEngine
        // playback. The iOS app in App/ is a thin shell around this target.
        .target(
            name: "PantryUI",
            dependencies: ["PantryScoring", "PantryGame"],
            path: "Sources/PantryUI"
        ),
        .testTarget(
            name: "PantryGameTests",
            dependencies: ["PantryScoring", "PantryGame"],
            path: "Tests/PantryGameTests"
        ),
        .testTarget(
            name: "PantryScoringTests",
            dependencies: ["PantryScoring"],
            path: "Tests/PantryScoringTests",
            resources: [.copy("Fixtures")]
        ),
    ]
)
