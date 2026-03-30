import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ToolsView()
                .tabItem {
                    Label("Инструменты", systemImage: "wrench.and.screwdriver")
                }
                .tag(0)
            
            SettingsView()
                .tabItem {
                    Label("Настройки", systemImage: "gear")
                }
                .tag(1)
        }
    }
}

struct ToolsView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: TelegraphIPLoggerView()) {
                    HStack {
                        Image(systemName: "link.circle.fill")
                            .foregroundColor(.blue)
                        Text("Telegraph IP Logger")
                    }
                }
                
                NavigationLink(destination: DomainCheckerView()) {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.green)
                        Text("Domain Checker")
                    }
                }
                
                NavigationLink(destination: IPCheckerView()) {
                    HStack {
                        Image(systemName: "network")
                            .foregroundColor(.orange)
                        Text("IP Checker")
                    }
                }
                
                NavigationLink(destination: SherlockSearchView()) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.purple)
                        Text("Sherlock Search")
                    }
                }
            }
            .navigationTitle("Catalist v3")
        }
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("О приложении")) {
                    HStack {
                        Text("Версия")
                        Spacer()
                        Text("3.0")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Настройки")
        }
    }
}

#Preview {
    ContentView()
}
