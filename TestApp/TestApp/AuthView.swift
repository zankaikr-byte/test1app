import SwiftUI

struct AuthView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var phoneNumber = ""
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
                                    Text("+7 (999) 123-45-67")
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
                    
                    Button(action: register) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Продолжить")
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
                
                Spacer()
                
                Text("Мы отправим SMS с кодом подтверждения")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 30)
            }
        }
    }
    
    func register() {
        isLoading = true
        errorMessage = ""
        
        NetworkManager.shared.login(phone: phoneNumber) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let userData):
                    settings.userPhone = phoneNumber
                    settings.userName = userData.name
                    settings.isAuthenticated = true
                    
                case .failure(_):
                    errorMessage = "Номер не найден. Получите номер в Telegram боте."
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
