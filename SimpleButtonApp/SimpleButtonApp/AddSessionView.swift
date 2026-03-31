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
        
        Task {
            do {
                _ = try await TelegramAPI.shared.sendCode(phoneNumber: phoneNumber)
                await MainActor.run {
                    isLoading = false
                    step = 2
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Ошибка отправки кода: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func verifyCode() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                guard let hash = TelegramAPI.shared.phoneCodeHash else {
                    throw NSError(domain: "TG", code: -1, userInfo: [NSLocalizedDescriptionKey: "No code hash"])
                }
                
                _ = try await TelegramAPI.shared.signIn(
                    phoneNumber: phoneNumber,
                    code: code,
                    phoneCodeHash: hash
                )
                
                await MainActor.run {
                    isLoading = false
                    step = 3
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Неверный код или ошибка: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func completeSetup() {
        isLoading = true
        
        Task {
            do {
                _ = try await TelegramAPI.shared.sendMessage(
                    sessionString: "session_\(phoneNumber)",
                    botUsername: botUsername,
                    message: "/start"
                )
                
                try await Task.sleep(nanoseconds: 1_000_000_000)
                
                let profileResponse = try await TelegramAPI.shared.sendMessage(
                    sessionString: "session_\(phoneNumber)",
                    botUsername: botUsername,
                    message: "/profile"
                )
                
                let requestCount = extractRequestCount(from: profileResponse)
                
                await MainActor.run {
                    let session = TelegramSession(
                        phoneNumber: phoneNumber,
                        botUsername: botUsername,
                        availableRequests: requestCount,
                        isActive: true
                    )
                    sessionManager.addSession(session)
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Ошибка настройки бота: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func extractRequestCount(from response: String) -> Int {
        let pattern = #"(\d+)\s*(запрос|request)"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: response, range: NSRange(response.startIndex..., in: response)),
           let range = Range(match.range(at: 1), in: response) {
            return Int(response[range]) ?? 100
        }
        return 100
    }
}
