import SwiftUI

struct AddSessionView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var sessionManager: TelegramSessionManager
    
    @State private var phoneNumber = ""
    @State private var code = ""
    @State private var botUsername = ""
    @State private var step = 1
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.cyan.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Image(systemName: "paperplane.circle.fill")
                        .font(.system(size: 70))
                        .foregroundColor(.blue)
                        .padding(.top, 20)
                    
                    Text("Добавить сессию")
                        .font(.title2.bold())
                    
                    if step == 1 {
                        VStack(spacing: 16) {
                            TextField("Номер телефона", text: $phoneNumber)
                                .keyboardType(.phonePad)
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                            
                            Button("Отправить код") {
                                sendCode()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(phoneNumber.isEmpty || isLoading)
                        }
                    } else if step == 2 {
                        VStack(spacing: 16) {
                            Text("Код отправлен на \(phoneNumber)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextField("Код подтверждения", text: $code)
                                .keyboardType(.numberPad)
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                            
                            Button("Подтвердить") {
                                verifyCode()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(code.isEmpty || isLoading)
                        }
                    } else if step == 3 {
                        VStack(spacing: 16) {
                            Text("Укажите бота для Sherlock Search")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextField("@sherlock_bot", text: $botUsername)
                                .autocapitalization(.none)
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                            
                            Button("Завершить") {
                                completeSetup()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(botUsername.isEmpty || isLoading)
                        }
                    }
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    if isLoading {
                        ProgressView()
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    func sendCode() {
        isLoading = true
        errorMessage = ""
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
            step = 2
        }
    }
    
    func verifyCode() {
        isLoading = true
        errorMessage = ""
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
            if code.count >= 5 {
                step = 3
            } else {
                errorMessage = "Неверный код"
            }
        }
    }
    
    func completeSetup() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let session = TelegramSession(
                phoneNumber: phoneNumber,
                botUsername: botUsername,
                availableRequests: 100,
                isActive: true
            )
            sessionManager.addSession(session)
            isLoading = false
            dismiss()
        }
    }
}
