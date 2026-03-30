import SwiftUI

struct IPCheckerView: View {
    @State private var ipAddress = ""
    @State private var result = ""
    @State private var isChecking = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.orange.opacity(0.1), Color.red.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "network")
                    .font(.system(size: 70))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(.top, 40)
                
                Text("IP Checker")
                    .font(.system(size: 28, weight: .bold))
                
                VStack(spacing: 16) {
                    TextField("Введите IP адрес", text: $ipAddress)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 5)
                        .keyboardType(.numbersAndPunctuation)
                    
                    Button("Проверить") {
                        isChecking = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            result = """
                            IP: \(ipAddress)
                            
                            🌍 Страна: Russia
                            🏙️ Город: Moscow
                            📡 Провайдер: Example ISP
                            🏠 Тип: Residential
                            📍 Координаты: 55.7558° N, 37.6173° E
                            🕐 Timezone: UTC+3
                            """
                            isChecking = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
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
