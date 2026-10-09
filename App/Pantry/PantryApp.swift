import PantryUI
import SwiftUI

/// The app is a shell. The screen, the round logic and the scoring all live in the
/// Swift package at the repository root, where they build and test without Xcode.
@main
struct PantryApp: App {
    var body: some Scene {
        WindowGroup {
            PantryRootView()
        }
    }
}
