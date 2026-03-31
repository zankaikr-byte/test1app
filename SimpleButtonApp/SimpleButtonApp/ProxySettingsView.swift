import SwiftUI

class ProxyManager: ObservableObject {
    @Published var isEnabled = false
    @AppStorage("proxy_enabled") private var savedEnabled = false
    @AppStorage("proxy_host") var proxyHost = ""
    @AppStorage("proxy_port") var proxyPort = "1080"
    @AppStorage("proxy_type") var proxyType = "socks5"
    @AppStorage("proxy_username") var proxyUsername = ""
    @AppStorage("proxy_password") var proxyPassword = ""
    
    init() {
        isEnabled = savedEnabled
    }
    
    func toggleProxy() {
        isEnabled.toggle()
        savedEnabled = isEnabled
        
        if isEnabled {
            configureSystemProxy()
        } else {
            removeSystemProxy()
        }
    }
    
    func configureSystemProxy() {
        guard !proxyHost.isEmpty else { return }
        
        let config = URLSessionConfiguration.default
        config.connectionProxyDictionary = [
            kCFNetworkProxiesHTTPEnable: true,
            kCFNetworkProxiesHTTPProxy: proxyHost,
            kCFNetworkProxiesHTTPPort: Int(proxyPort) ?? 1080,
            kCFProxyTypeKey: proxyType == "socks5" ? kCFProxyTypeSOCKS : kCFProxyTypeHTTP
        ]
        
        URLSession.shared.configuration.connectionProxyDictionary = config.connectionProxyDictionary
    }
    
    func removeSystemProxy() {
        URLSession.shared.configuration.connectionProxyDictionary = nil
    }
}

struct ProxySettingsView: View {
    @StateObject private var proxyManager = ProxyManager()
    
    var body: some View {
        Form {
            Section(header: Text("Статус")) {
                Toggle("Использовать прокси", isOn: $proxyManager.isEnabled)
                    .onChange(of: proxyManager.isEnabled) {
                        proxyManager.toggleProxy()
                    }
            }
            
            Section(header: Text("Конфигурация")) {
                Picker("Тип", selection: $proxyManager.proxyType) {
                    Text("SOCKS5").tag("socks5")
                    Text("HTTP").tag("http")
                    Text("HTTPS").tag("https")
                }
                
                TextField("Хост", text: $proxyManager.proxyHost)
                    .autocapitalization(.none)
                
                TextField("Порт", text: $proxyManager.proxyPort)
                    .keyboardType(.numberPad)
            }
            
            Section(header: Text("Авторизация (опционально)")) {
                TextField("Username", text: $proxyManager.proxyUsername)
                    .autocapitalization(.none)
                
                SecureField("Password", text: $proxyManager.proxyPassword)
            }
            
            Section(header: Text("Примеры")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("SOCKS5:")
                        .font(.caption.bold())
                    Text("127.0.0.1:1080")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("HTTP:")
                        .font(.caption.bold())
                        .padding(.top, 4)
                    Text("proxy.example.com:8080")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section {
                Button("Тест подключения") {
                    testProxy()
                }
                .foregroundColor(.blue)
            }
        }
        .navigationTitle("Настройки прокси")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func testProxy() {
        Task {
            do {
                let url = URL(string: "https://api.ipify.org?format=json")!
                let (data, _) = try await URLSession.shared.data(from: url)
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                   let ip = json["ip"] {
                    print("Proxy IP: \(ip)")
                }
            } catch {
                print("Proxy test failed: \(error)")
            }
        }
    }
}
