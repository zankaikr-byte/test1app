import SwiftUI

struct SherlockSearchView: View {
    @State private var username = ""
    @State private var result = ""
    @State private var isSearching = false
    @State private var foundCount = 0
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.pink.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 70))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(.top, 40)
                
                Text("Sherlock Search")
                    .font(.system(size: 28, weight: .bold))
                
                VStack(spacing: 16) {
                    TextField("Введите username", text: $username)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 5)
                        .autocapitalization(.none)
                    
                    Button("Найти") {
                        isSearching = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            foundCount = Int.random(in: 5...15)
                            result = """
                            Поиск username: \(username)
                            Найдено: \(foundCount) профилей
                            
                            ✓ GitHub: github.com/\(username)
                            ✓ Twitter: twitter.com/\(username)
                            ✓ Instagram: instagram.com/\(username)
                            ✗ Facebook: не найден
                            ✓ Reddit: reddit.com/u/\(username)
                            ✓ YouTube: youtube.com/@\(username)
                            ✓ TikTok: tiktok.com/@\(username)
                            ✓ LinkedIn: linkedin.com/in/\(username)
                            ✗ Pinterest: не найден
                            ✓ Telegram: t.me/\(username)
                            """
                            isSearching = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    .disabled(isSearching || username.isEmpty)
                }
                .padding()
                
                if isSearching {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Сканирование...")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                
                if !result.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Результаты")
                                .font(.headline)
                            Spacer()
                            Text("\(foundCount) найдено")
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.purple.opacity(0.2))
                                .cornerRadius(12)
                        }
                        
                        ScrollView {
                            Text(result)
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 8)
                    .padding()
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
