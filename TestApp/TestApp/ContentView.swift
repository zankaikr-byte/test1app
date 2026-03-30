import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 1
    @State private var hideTabBar = false
    @State private var totalUnreadCount = 0
    @EnvironmentObject var settings: AppSettings
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                ContactsView()
                    .tag(0)
                
                ChatsListView(hideTabBar: $hideTabBar, totalUnreadCount: $totalUnreadCount)
                    .tag(1)
                
                SettingsView()
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Custom Tab Bar - Telegram style with Glass effect
            if !hideTabBar {
                GlassTabBar(
                    selectedTab: $selectedTab,
                    totalUnreadCount: totalUnreadCount,
                    settings: settings
                )
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: hideTabBar)
            }
        }
    }
}

struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let badge: Int?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: 26, weight: .medium))
                        .foregroundColor(isSelected ? .blue : .gray)
                    
                    if let badge = badge, badge > 0 {
                        Text("\(badge)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.red)
                            .clipShape(Capsule())
                            .offset(x: 12, y: -8)
                    }
                }
                
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(TabBarButtonStyle())
    }
}

struct TabBarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct ChatsListView: View {
    @State private var searchText = ""
    @State private var isEditMode = false
    @State private var chats: [ChatData] = []
    @State private var searchResults: [UserData] = []
    @State private var isSearching = false
    @Binding var hideTabBar: Bool
    @Binding var totalUnreadCount: Int
    @EnvironmentObject var settings: AppSettings
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                backgroundView
                
                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(searchText.isEmpty ? .gray : .blue)
                            .animation(.easeInOut(duration: 0.2), value: searchText.isEmpty)
                        
                        TextField(settings.localizedString("search"), text: $searchText)
                            .onChange(of: searchText) { newValue in
                                if !newValue.isEmpty {
                                    performSearch(query: newValue)
                                } else {
                                    searchResults = []
                                    isSearching = false
                                }
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    searchText = ""
                                    searchResults = []
                                    isSearching = false
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(searchText.isEmpty ? Color.clear : Color.blue.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .animation(.easeInOut(duration: 0.2), value: searchText.isEmpty)
                    
                    // Content
                    ScrollView {
                        VStack(spacing: 0) {
                            if isSearching && !searchResults.isEmpty {
                                // Search results
                                ForEach(searchResults, id: \.phone) { user in
                                    NavigationLink(destination: ChatView(
                                        contactPhone: user.phone,
                                        contactName: user.name,
                                        hideTabBar: $hideTabBar
                                    )) {
                                        SearchResultRow(user: user)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    Divider()
                                        .padding(.leading, 76)
                                }
                            } else if chats.isEmpty && !isSearching {
                                // Empty state
                                VStack(spacing: 16) {
                                    Image(systemName: "message.badge.circle")
                                        .font(.system(size: 64))
                                        .foregroundColor(.gray.opacity(0.5))
                                    
                                    Text("Нет чатов")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.gray)
                                    
                                    Text("Используйте поиск выше, чтобы найти пользователей по номеру или имени")
                                        .font(.system(size: 15))
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 40)
                                }
                                .padding(.top, 100)
                                .transition(.scale.combined(with: .opacity))
                            } else if !isSearching {
                                // Chats list
                                ForEach(chats, id: \.contact_phone) { chat in
                                    NavigationLink(destination: ChatView(
                                        contactPhone: chat.contact_phone,
                                        contactName: chat.contact_name,
                                        hideTabBar: $hideTabBar
                                    )) {
                                        ChatRow(chat: chat, isEditMode: isEditMode)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    Divider()
                                        .padding(.leading, 76)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(settings.localizedString("chats"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
        }
        .onAppear {
            loadChats()
        }
    }
    
    func loadChats() {
        NetworkManager.shared.getChats(phone: settings.userPhone) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let loadedChats):
                    self.chats = loadedChats
                    // Calculate total unread count
                    self.totalUnreadCount = loadedChats.reduce(0) { $0 + $1.unread_count }
                case .failure(let error):
                    print("Error loading chats: \(error)")
                }
            }
        }
    }
    
    func performSearch(query: String) {
        isSearching = true
        NetworkManager.shared.searchUsers(query: query) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let users):
                    // Filter out current user
                    self.searchResults = users.filter { $0.phone != settings.userPhone }
                case .failure(let error):
                    print("Search error: \(error)")
                    self.searchResults = []
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

struct SearchResultRow: View {
    let user: UserData
    
    var avatarColor: Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .red, .cyan, .indigo]
        let hash = abs(user.phone.hashValue)
        return colors[hash % colors.count]
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar with icon
            ZStack {
                Circle()
                    .fill(avatarColor)
                    .frame(width: 52, height: 52)
                
                if user.name.isEmpty {
                    Image(systemName: "person.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 24))
                } else {
                    Text(String(user.name.prefix(2)).uppercased())
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .medium))
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name.isEmpty ? "User" : user.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    if let username = user.username, !username.isEmpty {
                        Text("@\(username)")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Text("•")
                            .foregroundColor(.gray)
                    }
                    Text(user.phone)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray.opacity(0.3))
                .font(.system(size: 14))
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground).opacity(0.8))
    }
}

struct ContactsView: View {
    @EnvironmentObject var settings: AppSettings
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "person.2.circle")
                    .font(.system(size: 64))
                    .foregroundColor(.gray)
                Text("Контакты")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.gray)
                Text("Используйте поиск в чатах для поиска пользователей")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle(settings.localizedString("contacts"))
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct ChatRow: View {
    let chat: ChatData
    var isEditMode: Bool = false
    
    var avatarColor: Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .red, .cyan, .indigo]
        let hash = abs(chat.contact_phone.hashValue)
        return colors[hash % colors.count]
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if isEditMode {
                Button(action: {}) {
                    Image(systemName: "circle")
                        .foregroundColor(.blue)
                }
            }
            
            // Avatar with icon
            ZStack {
                Circle()
                    .fill(avatarColor)
                    .frame(width: 52, height: 52)
                
                if chat.contact_name.isEmpty {
                    Image(systemName: "person.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 24))
                } else {
                    Text(String(chat.contact_name.prefix(2)).uppercased())
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .medium))
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(chat.contact_name.isEmpty ? "User" : chat.contact_name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                    Text(formatTime(chat.last_message_time))
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                HStack {
                    if !chat.last_message.isEmpty {
                        Text(chat.last_message)
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    } else {
                        Text("Нет сообщений")
                            .font(.system(size: 15))
                            .foregroundColor(.gray.opacity(0.6))
                            .italic()
                    }
                    Spacer()
                    if chat.unread_count > 0 {
                        Text("\(chat.unread_count)")
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
        .background(Color(.systemBackground).opacity(0.8))
    }
    
    func formatTime(_ isoString: String) -> String {
        guard !isoString.isEmpty else { return "" }
        
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else { return "" }
        
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            return timeFormatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d"
            return dateFormatter.string(from: date)
        }
    }
}

// MARK: - Glass Tab Bar Component
struct GlassTabBar: View {
    @Binding var selectedTab: Int
    let totalUnreadCount: Int
    let settings: AppSettings
    @State private var selectionOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Glass background container
                GlassBackground()
                    .frame(height: 64)
                
                // Selection indicator (liquid lens effect simulation)
                SelectionIndicator(selectedTab: selectedTab)
                    .frame(height: 64)
                
                // Tab buttons
                HStack(spacing: 0) {
                    TabBarButton(
                        icon: "person.2.fill",
                        title: settings.localizedString("contacts"),
                        isSelected: selectedTab == 0,
                        badge: nil
                    ) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            selectedTab = 0
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    TabBarButton(
                        icon: "message.fill",
                        title: settings.localizedString("chats"),
                        isSelected: selectedTab == 1,
                        badge: totalUnreadCount > 0 ? totalUnreadCount : nil
                    ) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            selectedTab = 1
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    TabBarButton(
                        icon: "gearshape.fill",
                        title: settings.localizedString("settings"),
                        isSelected: selectedTab == 2,
                        badge: nil
                    ) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            selectedTab = 2
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 8)
            }
        }
        .frame(height: 64)
    }
}

// MARK: - Glass Background
struct GlassBackground: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Base blur
            RoundedRectangle(cornerRadius: 32)
                .fill(.ultraThinMaterial)
            
            // Glass tint overlay
            RoundedRectangle(cornerRadius: 32)
                .fill(
                    colorScheme == .dark
                        ? Color.white.opacity(0.08)
                        : Color.white.opacity(0.6)
                )
                .blendMode(colorScheme == .dark ? .plusLighter : .normal)
            
            // Inner glow
            RoundedRectangle(cornerRadius: 32)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.3 : 0.6),
                            Color.white.opacity(0.0),
                            Color.white.opacity(colorScheme == .dark ? 0.15 : 0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            
            // Outer shadow
            RoundedRectangle(cornerRadius: 32)
                .fill(Color.clear)
                .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        }
    }
}

// MARK: - Selection Indicator (Liquid Lens Simulation)
struct SelectionIndicator: View {
    let selectedTab: Int
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            let itemWidth = geometry.size.width / 3
            let offset = CGFloat(selectedTab) * itemWidth
            
            ZStack {
                // Selection blob
                Capsule()
                    .fill(
                        colorScheme == .dark
                            ? Color.white.opacity(0.12)
                            : Color.white.opacity(0.4)
                    )
                    .frame(width: itemWidth - 16, height: 48)
                    .offset(x: offset - geometry.size.width / 2 + itemWidth / 2)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                    .blendMode(.plusLighter)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
