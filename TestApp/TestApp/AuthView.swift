import SwiftUI

struct AuthView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var phoneNumber = ""
    @State private var verificationCode = ""
    @State private var isCodeSent = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    
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
                        .background(phoneNumber.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(12)
                        .disabled(phoneNumber.isEmpty || isLoading)
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
                
                Text(isCodeSent ? "Код отправлен на сервер (проверьте консоль)" : "Мы отправим код подтверждения")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 30)
            }
        }
    }
    
    func requestCode() {
        isLoading = true
        errorMessage = ""
        
        NetworkManager.shared.requestCode(phone: phoneNumber) { result in
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
        
        NetworkManager.shared.verifyCode(phone: phoneNumber, code: verificationCode) { result in
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
