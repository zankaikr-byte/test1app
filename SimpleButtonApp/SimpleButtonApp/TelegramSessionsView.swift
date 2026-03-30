import SwiftUI

struct TelegramSessionsView: View {
    @StateObject private var sessionManager = TelegramSessionManager()
    @State private var showingAddSession = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.cyan.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack {
                    if sessionManager.sessions.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "paperplane.circle")
                                .font(.system(size: 80))
                                .foregroundColor(.blue)
                            
                            Text("Нет сессий")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            
                            Text("Добавьте Telegram сессию для использования Sherlock Search")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    } else {
                        List {
                            ForEach(sessionManager.sessions) { session in
                                SessionRow(session: session)
                            }
                            .onDelete(perform: sessionManager.deleteSession)
                        }
                    }
                }
                .navigationTitle("Telegram Сессии")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingAddSession = true }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .sheet(isPresented: $showingAddSession) {
                    AddSessionView(sessionManager: sessionManager)
                }
            }
        }
    }
}

struct SessionRow: View {
    let session: TelegramSession
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(session.phoneNumber)
                    .font(.headline)
                
                Text("Bot: \(session.botUsername)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Запросов: \(session.availableRequests)")
                    .font(.caption2)
                    .foregroundColor(session.availableRequests > 0 ? .green : .red)
            }
            
            Spacer()
            
            Circle()
                .fill(session.isActive ? Color.green : Color.gray)
                .frame(width: 12, height: 12)
        }
        .padding(.vertical, 8)
    }
}
