import SwiftUI

struct SherlockSearchView: View {
    @State private var username = ""
    @State private var result = ""
    @State private var isSearching = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Sherlock Search")
                .font(.title)
                .padding()
            
            TextField("Введите username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Найти") {
                isSearching = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    result = """
                    Поиск username: \(username)
                    
                    ✓ GitHub: найден
                    ✓ Twitter: найден
                    ✓ Instagram: найден
                    ✗ Facebook: не найден
                    ✓ Reddit: найден
                    """
                    isSearching = false
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSearching)
            
            if isSearching {
                ProgressView()
                    .padding()
            }
            
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
        .navigationTitle("Sherlock Search")
    }
}
