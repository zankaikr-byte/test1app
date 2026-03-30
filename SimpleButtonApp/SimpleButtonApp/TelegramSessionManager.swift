import Foundation
import SwiftUI

struct TelegramSession: Identifiable, Codable {
    let id: UUID
    var phoneNumber: String
    var botUsername: String
    var availableRequests: Int
    var isActive: Bool
    
    init(id: UUID = UUID(), phoneNumber: String, botUsername: String, availableRequests: Int, isActive: Bool) {
        self.id = id
        self.phoneNumber = phoneNumber
        self.botUsername = botUsername
        self.availableRequests = availableRequests
        self.isActive = isActive
    }
}

class TelegramSessionManager: ObservableObject {
    @Published var sessions: [TelegramSession] = []
    
    private let sessionsKey = "telegram_sessions"
    
    init() {
        loadSessions()
    }
    
    func loadSessions() {
        if let data = UserDefaults.standard.data(forKey: sessionsKey),
           let decoded = try? JSONDecoder().decode([TelegramSession].self, from: data) {
            sessions = decoded
        }
    }
    
    func saveSessions() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: sessionsKey)
        }
    }
    
    func addSession(_ session: TelegramSession) {
        sessions.append(session)
        saveSessions()
    }
    
    func deleteSession(at offsets: IndexSet) {
        sessions.remove(atOffsets: offsets)
        saveSessions()
    }
    
    func updateRequestCount(for sessionId: UUID, newCount: Int) {
        if let index = sessions.firstIndex(where: { $0.id == sessionId }) {
            sessions[index].availableRequests = newCount
            saveSessions()
        }
    }
    
    func getActiveSessionWithRequests() -> TelegramSession? {
        return sessions.first { $0.isActive && $0.availableRequests > 0 }
    }
}
