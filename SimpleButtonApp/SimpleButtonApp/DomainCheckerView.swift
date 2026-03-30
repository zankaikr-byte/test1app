import SwiftUI

struct DomainCheckerView: View {
    @State private var domain = ""
    @State private var result = ""
    @State private var isChecking = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.green.opacity(0.1), Color.mint.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "globe")
                    .font(.system(size: 70))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(.top, 40)
                
                Text("Domain Checker")
                    .font(.system(size: 28, weight: .bold))
                
                VStack(spacing: 16) {
                    TextField("Введите домен", text: $domain)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 5)
                        .autocapitalization(.none)
                    
                    Button("Проверить") {
                        isChecking = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            result = """
                            Домен: \(domain)
                            Статус: ✓ Активен
                            Регистратор: Example Registrar
                            Дата создания: 2020-01-01
                            Истекает: 2027-01-01
                            DNS: Cloudflare
                            """
                            isChecking = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .disabled(isChecking)
                }
                .padding()
                
                if isChecking {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                }
                
                if !result.isEmpty {
                    ScrollView {
                        Text(result)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.1), radius: 5)
                    }
                    .padding()
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
