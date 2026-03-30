import SwiftUI

struct DomainCheckerView: View {
    @State private var domain = ""
    @State private var result = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Domain Checker")
                .font(.title)
                .padding()
            
            TextField("Введите домен", text: $domain)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Проверить") {
                result = "Домен: \(domain)\nСтатус: Активен\nРегистратор: Example Registrar\nДата создания: 2020-01-01"
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
        .navigationTitle("Domain Checker")
    }
}
