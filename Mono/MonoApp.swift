import SwiftUI

@main
struct MonoApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(DataManager.shared)
                .environmentObject(SettingsManager())
                .environmentObject(AIServiceManager.shared)
        }
    }
}
