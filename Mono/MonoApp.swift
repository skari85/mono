import SwiftUI
import SwiftData

@main
struct MonoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(DataManager.shared.modelContainer)
        }
    }
}
