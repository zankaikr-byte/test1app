import SwiftUI

struct TelegraphIPLoggerView: View {
    @State private var loggerURL = ""
    @State private var generatedLink = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Telegraph IP Logger")
                .font(.title)
                .padding()
            
            TextField("Введите URL для логирования", text: $loggerURL)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Создать ссылку") {
                generatedLink = "https://telegra.ph/logger-\(Int.random(in: 1000...9999))"
            }
            .buttonStyle(.borderedProminent)
            
            if !generatedLink.isEmpty {
                VStack {
                    Text("Сгенерированная ссылка:")
                        .font(.caption)
                    Text(generatedLink)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Telegraph IP Logger")
    }
}
