import SwiftUI

struct AuthView: View {
    @EnvironmentObject var settings: AppSettings
    @StateObject private var networkManager = NetworkManager.shared
    @State private var phoneNumber = ""
    @State private var verificationCode = ""
    @State private var customIP = ""
    @State private var isCodeSent = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showIPInput = false
    @State private var serverStatus = "Поиск сервера..."
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Logo
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                
                Text("Telegram Clone")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // Server status
                HStack {
                    if networkManager.isSearching {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else if !networkManager.currentIP.isEmpty {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(networkManager.isSearching ? "Поиск сервера..." : 
                             !networkManager.currentIP.isEmpty ? "Сервер: \(networkManager.currentIP)" : 
                             "Сервер не найден")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.caption)
                        
                        if networkManager.ping > 0 {
                            Text("Пинг: \(networkManager.ping)ms")
                                .foregroundColor(.green.opacity(0.8))
                                .font(.caption2)
                        }
                    }
                }
                .padding(.horizontal, 40)
                
                Button(action: { showIPInput.toggle() }) {
                    Text(showIPInput ? "Скрыть настройки" : "⚙️ Настроить IP")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.caption)
                }
                
                if showIPInput {
                    VStack(spacing: 10) {
                        HStack {
                            Image(systemName: "network")
                                .foregroundColor(.white.opacity(0.6))
                            
                            TextField("", text: $customIP)
                                .placeholder(when: customIP.isEmpty) {
                                    Text("192.168.1.120")
                                        .foregroundColor(.white.opacity(0.4))
                                }
                                .foregroundColor(.white)
                                .keyboardType(.URL)
                                .autocapitalization(.none)
                        }
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                        
                        HStack {
                            Button(action: {
                                networkManager.setCustomIP(customIP)
                                showIPInput = false
                            }) {
                                Text("Применить")
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.green)
                                    .cornerRadius(8)
                            }
                            .disabled(customIP.isEmpty)
                            
                            Button(action: {
                                networkManager.findServer { success in
                                    if !success {
                                        errorMessage = "Сервер не найден"
                                    }
                                }
                            }) {
                                Text("Автопоиск")
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                }
                
                Spacer()
                
                if !isCodeSent {
                    // Phone input
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ваш номер телефона")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.subheadline)
                            
                            HStack {
                                Image(systemName: "phone.fill")
                                    .foregroundColor(.white.opacity(0.6))
                                
                                TextField("", text: $phoneNumber)
                                    .placeholder(when: phoneNumber.isEmpty) {
                                        Text("+1 (555) 123-4567")
                                            .foregroundColor(.white.opacity(0.4))
                                    }
                                    .foregroundColor(.white)
                                    .keyboardType(.phonePad)
                            }
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                        }
                        
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        
                        Button(action: requestCode) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Получить код")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(phoneNumber.isEmpty || networkManager.currentIP.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(12)
                        .disabled(phoneNumber.isEmpty || isLoading || networkManager.currentIP.isEmpty)
                    }
                    .padding(.horizontal, 40)
                } else {
                    // Code input
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Код подтверждения")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.subheadline)
                            
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.white.opacity(0.6))
                                
                                TextField("", text: $verificationCode)
                                    .placeholder(when: verificationCode.isEmpty) {
                                        Text("123456")
                                            .foregroundColor(.white.opacity(0.4))
                                    }
                                    .foregroundColor(.white)
                                    .keyboardType(.numberPad)
                            }
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                        }
                        
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        
                        Button(action: verifyCode) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Войти")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(verificationCode.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(12)
                        .disabled(verificationCode.isEmpty || isLoading)
                        
                        Button(action: { isCodeSent = false }) {
                            Text("Изменить номер")
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 40)
                }
                
                Spacer()
                
                Text(isCodeSent ? "Код отображается в веб-панели" : "Получите номер в боте или веб-панели")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 30)
            }
        }
        .onAppear {
            // Автоматический поиск сервера при запуске
            if networkManager.currentIP.isEmpty {
                networkManager.findServer { success in
                    if !success {
                        serverStatus = "Сервер не найден. Настройте IP вручную."
                    }
                }
            }
        }
    }
    
    func requestCode() {
        isLoading = true
        errorMessage = ""
        
        networkManager.requestCode(phone: phoneNumber) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(_):
                    isCodeSent = true
                    
                case .failure(_):
                    errorMessage = "Номер не найден. Создайте аккаунт в боте или веб-панели."
                }
            }
        }
    }
    
    func verifyCode() {
        isLoading = true
        errorMessage = ""
        
        networkManager.verifyCode(phone: phoneNumber, code: verificationCode) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let userData):
                    settings.userPhone = phoneNumber
                    settings.userName = userData.name
                    settings.isAuthenticated = true
                    
                case .failure(_):
                    errorMessage = "Неверный код"
                }
            }
        }
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
