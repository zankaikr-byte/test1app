import SwiftUI

struct ChatView: View {
    let contactPhone: String
    let contactName: String
    @Binding var hideTabBar: Bool
    @State private var messageText = ""
    @State private var messages: [MessageData] = []
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var settings: AppSettings
    
    var avatarColor: Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .red, .cyan, .indigo]
        let hash = abs(contactPhone.hashValue)
        return colors[hash % colors.count]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollView {
                VStack(spacing: 12) {
                    if messages.isEmpty {
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(avatarColor)
                                    .frame(width: 80, height: 80)
                                
                                if contactName.isEmpty {
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.white)
                                        .font(.system(size: 40))
                                } else {
                                    Text(String(contactName.prefix(2)).uppercased())
                                        .foregroundColor(.white)
                                        .font(.system(size: 32, weight: .medium))
                                }
                            }
                            .padding(.top, 40)
                            
                            Text(contactName.isEmpty ? "User" : contactName)
                                .font(.system(size: 24, weight: .semibold))
                            
                            Text(contactPhone)
                                .font(.system(size: 15))
                                .foregroundColor(.gray)
                            
                            Text("Нет сообщений")
                                .font(.system(size: 15))
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        ForEach(messages, id: \.timestamp) { message in
                            MessageBubble(message: message, currentUserPhone: settings.userPhone)
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                                    removal: .scale(scale: 0.8).combined(with: .opacity)
                                ))
                        }
                    }
                }
                .padding()
            }
            
            // Input bar
            HStack(spacing: 8) {
                Button(action: {}) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.blue)
                }
                
                HStack {
                    TextField("Сообщение", text: $messageText)
                        .padding(.vertical, 8)
                    
                    if !messageText.isEmpty {
                        Button(action: {}) {
                            Image(systemName: "paperclip")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .background(Color(.systemGray6))
                .cornerRadius(20)
                
                if messageText.isEmpty {
                    Button(action: {}) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                    }
                } else {
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
        }
        .navigationTitle(contactName.isEmpty ? "User" : contactName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {}) {
                    ZStack {
                        Circle()
                            .fill(avatarColor)
                            .frame(width: 32, height: 32)
                        
                        if contactName.isEmpty {
                            Image(systemName: "person.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 16))
                        } else {
                            Text(String(contactName.prefix(2)).uppercased())
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .medium))
                        }
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                hideTabBar = true
            }
            loadMessages()
        }
        .onDisappear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                hideTabBar = false
            }
        }
    }
    
    func loadMessages() {
        NetworkManager.shared.getMessages(phone: settings.userPhone, contact: contactPhone) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let loadedMessages):
                    self.messages = loadedMessages
                case .failure(let error):
                    print("Error loading messages: \(error)")
                }
            }
        }
    }
    
    func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        let text = messageText
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            messageText = ""
        }
        
        NetworkManager.shared.sendMessage(from: settings.userPhone, to: contactPhone, text: text) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Reload messages with animation
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        loadMessages()
                    }
                case .failure(let error):
                    print("Error sending message: \(error)")
                }
            }
        }
    }
}

struct MessageBubble: View {
    let message: MessageData
    let currentUserPhone: String
    
    var isOutgoing: Bool {
        return message.from == currentUserPhone
    }
    
    var body: some View {
        HStack {
            if isOutgoing {
                Spacer()
            }
            
            VStack(alignment: isOutgoing ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isOutgoing ? Color.blue : Color(.systemGray5))
                    .foregroundColor(isOutgoing ? .white : .primary)
                    .cornerRadius(18)
                
                HStack(spacing: 4) {
                    Text(formatTime(message.timestamp))
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    if isOutgoing {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                    }
                }
            }
            
            if !isOutgoing {
                Spacer()
            }
        }
    }
    
    func formatTime(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else { return "" }
        
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        return timeFormatter.string(from: date)
    }
}
