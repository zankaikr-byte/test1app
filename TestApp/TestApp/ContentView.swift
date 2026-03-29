import SwiftUI

struct ContentView: View {
    @State private var searchText = ""
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ChatsListView()
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Chats")
                }
                .tag(0)
            
            ContactsView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Contacts")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(2)
        }
        .accentColor(.blue)
    }
}

struct ChatsListView: View {
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search", text: $searchText)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Chats list
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(mockChats) { chat in
                            NavigationLink(destination: ChatView(chat: chat)) {
                                ChatRow(chat: chat)
                            }
                            .buttonStyle(PlainButtonStyle())
                            Divider()
                                .padding(.leading, 76)
                        }
                    }
                }
            }
            .navigationTitle("Telegram")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
        }
    }
}

struct ContactsView: View {
    var body: some View {
        NavigationView {
            List {
                Section {
                    ContactRow(name: "Invite Friends", icon: "person.badge.plus", color: .blue)
                    ContactRow(name: "Find People Nearby", icon: "location.fill", color: .blue)
                }
                
                Section(header: Text("SORTED BY LAST SEEN")) {
                    ForEach(mockContacts) { contact in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(contact.color)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(contact.initials)
                                        .foregroundColor(.white)
                                        .font(.system(size: 16, weight: .medium))
                                )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(contact.name)
                                    .font(.system(size: 17))
                                Text(contact.status)
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Contacts")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct ContactRow: View {
    let name: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: icon)
                        .foregroundColor(.white)
                )
            
            Text(name)
                .font(.system(size: 17))
                .foregroundColor(.blue)
        }
    }
}

struct ChatRow: View {
    let chat: Chat
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(chat.color)
                .frame(width: 52, height: 52)
                .overlay(
                    Text(chat.initials)
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .medium))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(chat.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                    Text(chat.time)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                HStack {
                    if chat.isRead {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                    }
                    Text(chat.lastMessage)
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    Spacer()
                    if chat.unreadCount > 0 {
                        Text("\(chat.unreadCount)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

struct Chat: Identifiable {
    let id = UUID()
    let name: String
    let lastMessage: String
    let time: String
    let unreadCount: Int
    let isRead: Bool
    let color: Color
    let initials: String
}

struct Contact: Identifiable {
    let id = UUID()
    let name: String
    let status: String
    let color: Color
    let initials: String
}

let mockChats = [
    Chat(name: "Saved Messages", lastMessage: "You: Test message", time: "12:30", unreadCount: 0, isRead: true, color: .blue, initials: "📌"),
    Chat(name: "John Doe", lastMessage: "Hey! How are you?", time: "11:45", unreadCount: 3, isRead: false, color: .green, initials: "JD"),
    Chat(name: "Work Group", lastMessage: "Alice: Meeting at 3 PM", time: "10:20", unreadCount: 12, isRead: false, color: .orange, initials: "WG"),
    Chat(name: "Mom", lastMessage: "Don't forget to call", time: "Yesterday", unreadCount: 0, isRead: true, color: .pink, initials: "M"),
    Chat(name: "Dev Team", lastMessage: "Bob: Push to production?", time: "Yesterday", unreadCount: 5, isRead: false, color: .purple, initials: "DT"),
    Chat(name: "Sarah", lastMessage: "See you tomorrow!", time: "Monday", unreadCount: 0, isRead: true, color: .red, initials: "S"),
    Chat(name: "Crypto News", lastMessage: "Bitcoin hits new high", time: "Sunday", unreadCount: 0, isRead: false, color: .cyan, initials: "CN"),
]

let mockContacts = [
    Contact(name: "Alice Johnson", status: "online", color: .blue, initials: "AJ"),
    Contact(name: "Bob Smith", status: "last seen recently", color: .green, initials: "BS"),
    Contact(name: "Charlie Brown", status: "last seen 2 hours ago", color: .orange, initials: "CB"),
    Contact(name: "Diana Prince", status: "last seen yesterday", color: .purple, initials: "DP"),
]

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
