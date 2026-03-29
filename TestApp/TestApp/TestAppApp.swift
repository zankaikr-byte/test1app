import SwiftUI

@main
struct TestAppApp: App {
    @StateObject private var settings = AppSettings()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .preferredColorScheme(
                    settings.theme == "light" ? .light :
                    settings.theme == "dark" ? .dark : nil
                )
        }
    }
}
