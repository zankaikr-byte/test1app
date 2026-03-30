import SwiftUI

struct SearchHistoryItem: Identifiable, Codable {
    let id: UUID
    let query: String
    let result: String
    let timestamp: Date
    let sessionPhone: String
    
    init(id: UUID = UUID(), query: String, result: String, timestamp: Date = Date(), sessionPhone: String) {
        self.id = id
        self.query = query
        self.result = result
        self.timestamp = timestamp
        self.sessionPhone = sessionPhone
    }
}

class SearchHistoryManager: ObservableObject {
    @Published var history: [SearchHistoryItem] = []
    private let historyKey = "sherlock_history"
    
    init() {
        loadHistory()
    }
    
    func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([SearchHistoryItem].self, from: data) {
            history = decoded
        }
    }
    
    func saveHistory() {
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: historyKey)
        }
    }
    
    func addSearch(query: String, result: String, sessionPhone: String) {
        let item = SearchHistoryItem(query: query, result: result, sessionPhone: sessionPhone)
        history.insert(item, at: 0)
        saveHistory()
    }
}

struct SherlockSearchView: View {
    @StateObject private var sessionManager = TelegramSessionManager()
    @StateObject private var historyManager = SearchHistoryManager()
    @State private var searchQuery = ""
    @State private var result = ""
    @State private var isSearching = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.pink.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Image(systemName: "magnifyingglass.circle.fill")
                        .font(.system(size: 70))
                        .foregroundColor(.purple)
                        .padding(.top, 20)
                    
                    Text("Sherlock Search")
                        .font(.title.bold())
                    
                    if let session = sessionManager.getActiveSessionWithRequests() {
                        Text("Запросов: \(session.availableRequests)")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(8)
                    } else {
                        Text("Нет доступных сессий")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    VStack(spacing: 16) {
                        TextField("Username или номер", text: $searchQuery)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .autocapitalization(.none)
                        
                        Button("Поиск") {
                            performSearch()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                        .disabled(isSearching || searchQuery.isEmpty || sessionManager.getActiveSessionWithRequests() == nil)
                    }
                    .padding()
                    
                    if isSearching {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Отправка запроса через Telegram...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if !result.isEmpty {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Результат")
                                    .font(.headline)
                                
                                Text(result)
                                    .font(.system(.body, design: .monospaced))
                                    .textSelection(.enabled)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                            .padding()
                        }
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SearchHistoryView(historyManager: historyManager)) {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
            }
            .alert("Ошибка", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    func performSearch() {
        guard let session = sessionManager.getActiveSessionWithRequests() else {
            errorMessage = "Нет доступных сессий с запросами"
            showError = true
            return
        }
        
        isSearching = true
        result = ""
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let mockResult = """
            Поиск: \(searchQuery)
            Сессия: \(session.phoneNumber)
            Bot: \(session.botUsername)
            
            ✓ GitHub: github.com/\(searchQuery)
            ✓ Twitter: twitter.com/\(searchQuery)
            ✓ Instagram: instagram.com/\(searchQuery)
            ✓ Reddit: reddit.com/u/\(searchQuery)
            ✓ Telegram: t.me/\(searchQuery)
            ✓ VK: vk.com/\(searchQuery)
            
            Найдено: 6 профилей
            """
            
            result = mockResult
            historyManager.addSearch(query: searchQuery, result: mockResult, sessionPhone: session.phoneNumber)
            sessionManager.updateRequestCount(for: session.id, newCount: session.availableRequests - 1)
            isSearching = false
        }
    }
}

struct SearchHistoryView: View {
    @ObservedObject var historyManager: SearchHistoryManager
    
    var body: some View {
        List {
            ForEach(historyManager.history) { item in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(item.query)
                            .font(.headline)
                        Spacer()
                        Text(item.timestamp, style: .relative)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Сессия: \(item.sessionPhone)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(item.result)
                        .font(.caption)
                        .lineLimit(3)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("История поиска")
        .navigationBarTitleDisplayMode(.inline)
    }
}

