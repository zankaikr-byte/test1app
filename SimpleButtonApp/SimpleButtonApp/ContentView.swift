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
            
            VPNView()
                .tabItem {
                    Label("VPN", systemImage: "lock.shield")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Label("Настройки", systemImage: "gear")
                }
                .tag(2)
        }
        .accentColor(.purple)
    }
}

struct ToolsView: View {
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        Text("OSINT Tools")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .padding(.top, 20)
                        
                        ToolCard(
                            icon: "link.circle.fill",
                            title: "Telegraph IP Logger",
                            description: "Создание логгер-ссылок",
                            color: .blue,
                            destination: AnyView(TelegraphIPLoggerView())
                        )
                        
                        ToolCard(
                            icon: "globe",
                            title: "Domain Checker",
                            description: "Проверка доменов",
                            color: .green,
                            destination: AnyView(DomainCheckerView())
                        )
                        
                        ToolCard(
                            icon: "network",
                            title: "IP Checker",
                            description: "Информация по IP",
                            color: .orange,
                            destination: AnyView(IPCheckerView())
                        )
                        
                        ToolCard(
                            icon: "magnifyingglass",
                            title: "Sherlock Search",
                            description: "Поиск по username",
                            color: .purple,
                            destination: AnyView(SherlockSearchView())
                        )
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct ToolCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let destination: AnyView
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.system(size: 28))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
            )
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
