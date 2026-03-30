import SwiftUI

struct IPCheckerView: View {
    @State private var ipAddress = ""
    @State private var result = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("IP Checker")
                .font(.title)
                .padding()
            
            TextField("Введите IP адрес", text: $ipAddress)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Проверить") {
                result = """
                IP: \(ipAddress)
                Страна: Russia
                Город: Moscow
                Провайдер: Example ISP
                Тип: Residential
                """
            }
            .buttonStyle(.borderedProminent)
            
            if !result.isEmpty {
                ScrollView {
                    Text(result)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
                .padding()
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("IP Checker")
    }
}
