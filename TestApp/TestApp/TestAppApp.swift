import SwiftUI

@main
struct TestAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    handleURL(url)
                }
        }
    }
    
    func handleURL(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let host = components.host else { return }
        
        if host == "select", let option = components.queryItems?.first(where: { $0.name == "option" })?.value,
           let optionIndex = Int(option) {
            UserDefaults(suiteName: "group.testapp")?.set(optionIndex, forKey: "selectedOption")
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
