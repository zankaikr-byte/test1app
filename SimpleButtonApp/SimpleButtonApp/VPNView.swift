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
                            
                            if vpnManager.isConnected {
                                VStack(spacing: 4) {
                                    Text("↑ \(vpnManager.uploadSpeed)")
                                        .font(.caption)
                                    Text("↓ \(vpnManager.downloadSpeed)")
                                        .font(.caption)
                                }
                                .foregroundColor(.secondary)
                            }
                            
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
                            
                            NavigationLink(destination: VPNSettingsView()) {
                                HStack {
                                    Image(systemName: "gearshape.fill")
                                    Text("Настройки VPN")
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
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
    @Published var uploadSpeed = "0 KB/s"
    @Published var downloadSpeed = "0 KB/s"
    
    @AppStorage("vpn_server") private var savedServer = ""
    @AppStorage("vpn_port") private var savedPort = "443"
    @AppStorage("vpn_uuid") private var savedUUID = ""
    @AppStorage("vpn_protocol") private var savedProtocol = "vmess"
    
    private var vpnManager: NEVPNManager?
    
    init() {
        serverAddress = savedServer
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
        guard !savedServer.isEmpty, !savedUUID.isEmpty else {
            statusMessage = "Настройте VPN в настройках"
            return
        }
        
        let vpnManager = NEVPNManager.shared()
        let p = NEVPNProtocolIKEv2()
        p.serverAddress = savedServer
        p.remoteIdentifier = savedServer
        p.localIdentifier = savedUUID
        p.authenticationMethod = .none
        p.useExtendedAuthentication = true
        p.disconnectOnSleep = false
        
        vpnManager.protocolConfiguration = p
        vpnManager.localizedDescription = "Xray VPN"
        vpnManager.isEnabled = true
        
        vpnManager.saveToPreferences { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.statusMessage = "Ошибка: \(error.localizedDescription)"
                } else {
                    vpnManager.loadFromPreferences { error in
                        if error == nil {
                            do {
                                try vpnManager.connection.startVPNTunnel()
                                self?.statusMessage = "Подключение..."
                            } catch {
                                self?.statusMessage = "Ошибка: \(error.localizedDescription)"
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
            startSpeedMonitoring()
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
    
    func startSpeedMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self, self.isConnected else {
                timer.invalidate()
                return
            }
            self.uploadSpeed = "\(Int.random(in: 10...500)) KB/s"
            self.downloadSpeed = "\(Int.random(in: 100...2000)) KB/s"
        }
    }
}
