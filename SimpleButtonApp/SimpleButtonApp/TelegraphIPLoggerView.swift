import SwiftUI

struct TelegraphIPLoggerView: View {
    @State private var loggerURL = ""
    @State private var generatedLink = ""
    @State private var showCopied = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.cyan.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "link.circle.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(.top, 40)
                
                Text("Telegraph IP Logger")
                    .font(.system(size: 28, weight: .bold))
                
                VStack(spacing: 16) {
                    TextField("Введите URL для логирования", text: $loggerURL)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 5)
                    
                    Button(action: {
                        generatedLink = "https://telegra.ph/logger-\(Int.random(in: 1000...9999))"
                    }) {
                        Text("Создать ссылку")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }
                .padding()
                
                if !generatedLink.isEmpty {
                    VStack(spacing: 12) {
                        Text("Сгенерированная ссылка:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text(generatedLink)
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Button(action: {
                                UIPasteboard.general.string = generatedLink
                                showCopied = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    showCopied = false
                                }
                            }) {
                                Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                                    .foregroundColor(.blue)
                            }
                            .padding(.trailing)
                        }
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
