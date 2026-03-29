import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var settings: AppSettings
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6), Color.pink.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                ChatsListView()
                    .tag(0)
                
                ContactsView()
                    .tag(1)
                
                SettingsView()
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Glass morphism Tab Bar
            HStack(spacing: 0) {
                TabBarButton(
                    icon: "person.2.fill",
                    title: settings.localizedString("contacts"),
                    badge: nil,
                    isSelected: selectedTab == 0
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = 0
                    }
                }
                
                TabBarButton(
                    icon: "message.fill",
                    title: settings.localizedString("chats"),
                    badge: 133,
                    isSelected: selectedTab == 1
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = 1
                    }
                }
                
                TabBarButton(
                    icon: "gearshape.fill",
                    title: settings.localizedString("settings"),
                    badge: nil,
                    isSelected: selectedTab == 2
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = 2
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    // Blur effect
                    RoundedRectangle(cornerRadius: 30)
                        .fill(.ultraThinMaterial)
                    
                    // Subtle gradient overlay
                    RoundedRectangle(cornerRadius: 30)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.1),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    // Border
                    RoundedRectangle(cornerRadius: 30)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
}

struct TabBarButton: View {
    let icon: String
    let title: String
    let badge: Int?
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(
                            isSelected ?
                            LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing) :
                            LinearGradient(colors: [.gray, .gray], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    
                    if let badge = badge {
                        Text("\(badge)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.red)
                            )
                            .offset(x: 12, y: -8)
                    }
                }
                
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.blue.opacity(0.15) : Color.clear)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
    }
}

struct ChatsListView: View {
    @State private var searchText = ""
    @State private var isEditMode = false
    @EnvironmentObject var settings: AppSettings
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                backgroundView
                
                VStack(spacing: 0) {
                    // Search bar with blur
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField(settings.localizedString("search"), text: $searchText)
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(10)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    // Chats list
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(mockChats) { chat in
                                NavigationLink(destination: ChatView(chat: chat)) {
                                    ChatRow(chat: chat, isEditMode: isEditMode)
                                        .background(.ultraThinMaterial)
                                        .cornerRadius(12)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle(settings.localizedString("chats"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(isEditMode ? "Done" : settings.localizedString("edit")) {
                        isEditMode.toggle()
                    }
                    .padding(8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 8) {
                        Button(action: {}) {
                            Image(systemName: "magnifyingglass")
                                .padding(8)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        Button(action: {}) {
                            Image(systemName: "square.and.pencil")
                                .padding(8)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                    }
                }
            }
        }
    }
    
    var backgroundView: some View {
        Group {
            if settings.chatBackground == "gradient" {
                LinearGradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
            } else if settings.chatBackground == "pattern" {
                Color.gray.opacity(0.1)
            } else {
                Color(.systemBackground)
            }
        }
        .ignoresSafeArea()
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
    var isEditMode: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            if isEditMode {
                Button(action: {}) {
                    Image(systemName: "circle")
                        .foregroundColor(.blue)
                }
            }
            
            // Avatar with blur
            Circle()
                .fill(chat.color.opacity(0.8))
                .frame(width: 52, height: 52)
                .overlay(
                    Text(chat.initials)
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .medium))
                )
                .shadow(color: chat.color.opacity(0.3), radius: 8)
            
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
                            .background(
                                Capsule()
                                    .fill(.blue)
                                    .shadow(color: .blue.opacity(0.5), radius: 4)
                            )
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
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
