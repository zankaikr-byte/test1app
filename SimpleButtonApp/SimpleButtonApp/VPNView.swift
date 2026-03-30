import SwiftUI
import NetworkExtension

struct VPNView: View {
    @StateObject private var vpnManager = VPNManager()
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Status Card
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(vpnManager.isConnected ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                                    .frame(width: 120, height: 120)
                                    .overlay(
                                        Circle()
                                            .stroke(vpnManager.isConnected ? Color.green : Color.gray, lineWidth: 3)
                                    )
                                
                                Image(systemName: vpnManager.isConnected ? "checkmark.shield.fill" : "shield.slash")
                                    .font(.system(size: 50))
                                    .foregroundColor(vpnManager.isConnected ? .green : .gray)
                            }
                            .padding(.top, 20)
                            
                            Text(vpnManager.isConnected ? "Подключено" : "Отключено")
                                .font(.system(size: 24, weight: .bold))
                            
                            Button(action: {
                                if vpnManager.isConnected {
                                    vpnManager.disconnect()
                                } else {
                                    vpnManager.connect()
                                }
                            }) {
                                HStack {
                                    Image(systemName: vpnManager.isConnected ? "xmark.circle" : "power")
                                    Text(vpnManager.isConnected ? "Отключить" : "Подключить")
                                }
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: vpnManager.isConnected ? [.red, .orange] : [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: (vpnManager.isConnected ? Color.red : Color.blue).opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .padding(.horizontal)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        )
                        .padding()
                        
                        // Configuration
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Настройки VPN")
                                .font(.system(size: 20, weight: .bold))
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                VPNConfigField(
                                    icon: "server.rack",
                                    title: "Сервер",
                                    value: $vpnManager.serverAddress,
                                    placeholder: "vpn.example.com"
                                )
                                
                                VPNConfigField(
                                    icon: "person.circle",
                                    title: "Username",
                                    value: $vpnManager.username,
                                    placeholder: "username"
                                )
                                
                                VPNConfigField(
                                    icon: "key.fill",
                                    title: "Password",
                                    value: $vpnManager.password,
                                    placeholder: "password",
                                    isSecure: true
                                )
                                
                                HStack {
                                    Image(systemName: "network")
                                        .foregroundColor(.purple)
                                        .frame(width: 30)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Протокол")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Picker("", selection: $vpnManager.protocol) {
                                            Text("IKEv2").tag("IKEv2")
                                            Text("IPSec").tag("IPSec")
                                            Text("L2TP").tag("L2TP")
                                        }
                                        .pickerStyle(SegmentedPickerStyle())
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                            )
                            .padding(.horizontal)
                        }
                        
                        if !vpnManager.statusMessage.isEmpty {
                            Text(vpnManager.statusMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct VPNConfigField: View {
    let icon: String
    let title: String
    @Binding var value: String
    let placeholder: String
    var isSecure: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if isSecure {
                    SecureField(placeholder, text: $value)
                        .textFieldStyle(PlainTextFieldStyle())
                } else {
                    TextField(placeholder, text: $value)
                        .textFieldStyle(PlainTextFieldStyle())
                        .autocapitalization(.none)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

class VPNManager: ObservableObject {
    @Published var isConnected = false
    @Published var serverAddress = ""
    @Published var username = ""
    @Published var password = ""
    @Published var `protocol` = "IKEv2"
    @Published var statusMessage = ""
    
    private var vpnManager: NEVPNManager?
    
    init() {
        loadVPNConfiguration()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(vpnStatusDidChange),
            name: .NEVPNStatusDidChange,
            object: nil
        )
    }
    
    func loadVPNConfiguration() {
        NEVPNManager.shared().loadFromPreferences { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.statusMessage = "Ошибка загрузки: \(error.localizedDescription)"
                } else {
                    self?.vpnManager = NEVPNManager.shared()
                    self?.updateConnectionStatus()
                }
            }
        }
    }
    
    func connect() {
        guard !serverAddress.isEmpty, !username.isEmpty, !password.isEmpty else {
            statusMessage = "Заполните все поля"
            return
        }
        
        let vpnManager = NEVPNManager.shared()
        
        let p = NEVPNProtocolIKEv2()
        p.serverAddress = serverAddress
        p.username = username
        p.passwordReference = Data(password.utf8) as Data
        p.authenticationMethod = .none
        p.useExtendedAuthentication = true
        p.disconnectOnSleep = false
        
        vpnManager.protocolConfiguration = p
        vpnManager.localizedDescription = "Catalist VPN"
        vpnManager.isEnabled = true
        
        vpnManager.saveToPreferences { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.statusMessage = "Ошибка сохранения: \(error.localizedDescription)"
                } else {
                    vpnManager.loadFromPreferences { error in
                        if error == nil {
                            do {
                                try vpnManager.connection.startVPNTunnel()
                                self?.statusMessage = "Подключение..."
                            } catch {
                                self?.statusMessage = "Ошибка подключения: \(error.localizedDescription)"
                            }
                        }
                    }
                }
            }
        }
    }
    
    func disconnect() {
        NEVPNManager.shared().connection.stopVPNTunnel()
        statusMessage = "Отключено"
    }
    
    @objc func vpnStatusDidChange() {
        DispatchQueue.main.async {
            self.updateConnectionStatus()
        }
    }
    
    func updateConnectionStatus() {
        let status = NEVPNManager.shared().connection.status
        switch status {
        case .connected:
            isConnected = true
            statusMessage = "✓ Соединение установлено"
        case .connecting:
            statusMessage = "Подключение..."
        case .disconnected:
            isConnected = false
            statusMessage = "Отключено"
        case .disconnecting:
            statusMessage = "Отключение..."
        case .reasserting:
            statusMessage = "Переподключение..."
        case .invalid:
            statusMessage = "Ошибка конфигурации"
        @unknown default:
            statusMessage = "Неизвестный статус"
        }
    }
}
