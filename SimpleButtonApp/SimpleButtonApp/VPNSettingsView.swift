import SwiftUI

struct VPNSettingsView: View {
    @AppStorage("vpn_server") private var vpnServer = ""
    @AppStorage("vpn_port") private var vpnPort = "443"
    @AppStorage("vpn_uuid") private var vpnUUID = ""
    @AppStorage("vpn_protocol") private var vpnProtocol = "vmess"
    @AppStorage("vpn_auto_connect") private var autoConnect = false
    
    var body: some View {
        Form {
            Section(header: Text("Конфигурация Xray")) {
                HStack {
                    Text("Протокол")
                    Spacer()
                    Picker("", selection: $vpnProtocol) {
                        Text("VMess").tag("vmess")
                        Text("VLess").tag("vless")
                        Text("Trojan").tag("trojan")
                        Text("Shadowsocks").tag("shadowsocks")
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                TextField("Сервер", text: $vpnServer)
                    .autocapitalization(.none)
                
                TextField("Порт", text: $vpnPort)
                    .keyboardType(.numberPad)
                
                TextField("UUID / Password", text: $vpnUUID)
                    .autocapitalization(.none)
                    .font(.system(.body, design: .monospaced))
            }
            
            Section(header: Text("Параметры")) {
                Toggle("Автоподключение", isOn: $autoConnect)
            }
            
            Section(header: Text("Импорт")) {
                Button("Импорт из буфера") {
                    importFromClipboard()
                }
                
                Button("Сканировать QR код") {
                    // QR scanner functionality
                }
            }
            
            Section {
                Button("Тест подключения") {
                    testConnection()
                }
                .foregroundColor(.blue)
            }
        }
        .navigationTitle("Настройки VPN")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func importFromClipboard() {
        // Parse vmess:// or vless:// links
    }
    
    func testConnection() {
        // Test VPN connection
    }
}
