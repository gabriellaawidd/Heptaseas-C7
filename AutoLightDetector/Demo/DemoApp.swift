import SwiftUI

/// Test harness for the Auto Light Detector service. Not the production UI,
/// which is built separately (PRD Scope).
@main
struct DemoApp: App {
    var body: some Scene {
        WindowGroup {
            DebugMirrorView()
                .preferredColorScheme(.dark)
                .statusBarHidden()
        }
    }
}
