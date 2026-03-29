import SwiftUI

struct ChatView: View {
    let chat: Chat
    @State private var messageText = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(mockMessages) { message in
                        MessageBubble(message: message)
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
                    TextField("Message", text: $messageText)
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
                    Button(action: {}) {
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
        .navigationTitle(chat.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {}) {
                    Circle()
                        .fill(chat.color)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(chat.initials)
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .medium))
                        )
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
    }
}

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isOutgoing {
                Spacer()
            }
            
            VStack(alignment: message.isOutgoing ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(message.isOutgoing ? Color.blue : Color(.systemGray5))
                    .foregroundColor(message.isOutgoing ? .white : .primary)
                    .cornerRadius(18)
                
                HStack(spacing: 4) {
                    Text(message.time)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    if message.isOutgoing {
                        Image(systemName: message.isRead ? "checkmark.circle.fill" : "checkmark.circle")
                            .font(.system(size: 12))
                            .foregroundColor(message.isRead ? .blue : .gray)
                    }
                }
            }
            
            if !message.isOutgoing {
                Spacer()
            }
        }
    }
}

struct Message: Identifiable {
    let id = UUID()
    let text: String
    let time: String
    let isOutgoing: Bool
    let isRead: Bool
}

let mockMessages = [
    Message(text: "Hey! How are you?", time: "10:30", isOutgoing: false, isRead: true),
    Message(text: "I'm good, thanks! What about you?", time: "10:32", isOutgoing: true, isRead: true),
    Message(text: "Great! Want to grab coffee later?", time: "10:33", isOutgoing: false, isRead: true),
    Message(text: "Sure! What time works for you?", time: "10:35", isOutgoing: true, isRead: true),
    Message(text: "How about 3 PM?", time: "10:36", isOutgoing: false, isRead: true),
    Message(text: "Perfect! See you then 👍", time: "10:37", isOutgoing: true, isRead: false),
]
