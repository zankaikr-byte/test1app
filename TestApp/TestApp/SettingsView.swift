import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    
    var avatarColor: Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .red, .cyan, .indigo]
        let hash = abs(settings.userPhone.hashValue)
        return colors[hash % colors.count]
    }
    
    var body: some View {
        NavigationView {
            List {
                // Profile section
                NavigationLink(destination: ProfileView()) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(avatarColor)
                                .frame(width: 64, height: 64)
                            
                            if settings.userName.isEmpty {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 32))
                            } else {
                                Text(String(settings.userName.prefix(2)).uppercased())
                                    .foregroundColor(.white)
                                    .font(.system(size: 24, weight: .medium))
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(settings.userName.isEmpty ? "User" : settings.userName)
                                .font(.system(size: 20, weight: .semibold))
                            
                            HStack(spacing: 4) {
                                if !settings.userUsername.isEmpty {
                                    Text("@\(settings.userUsername)")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                    Text("•")
                                        .foregroundColor(.gray)
                                }
                                Text(settings.userPhone)
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                // Account section
                Section {
                    NavigationLink(destination: AccountView()) {
                        SettingsRow(icon: "person.circle", title: settings.localizedString("account"), color: .blue)
                    }
                    NavigationLink(destination: PrivacyView()) {
                        SettingsRow(icon: "lock.circle", title: settings.localizedString("privacy"), color: .gray)
                    }
                    NavigationLink(destination: NotificationsView()) {
                        SettingsRow(icon: "bell.circle", title: settings.localizedString("notifications"), color: .red)
                    }
                    NavigationLink(destination: DataView()) {
                        SettingsRow(icon: "tray.circle", title: settings.localizedString("data"), color: .green)
                    }
                }
                
                // Appearance section
                Section {
                    NavigationLink(destination: AppearanceView()) {
                        SettingsRow(icon: "paintbrush.circle", title: settings.localizedString("appearance"), color: .cyan)
                    }
                    NavigationLink(destination: LanguageView()) {
                        SettingsRow(icon: "globe", title: settings.localizedString("language"), color: .orange)
                    }
                    NavigationLink(destination: StickersView()) {
                        SettingsRow(icon: "face.smiling", title: settings.localizedString("stickers"), color: .purple)
                    }
                }
                
                // Chat Settings
                Section {
                    NavigationLink(destination: ChatSettingsView()) {
                        SettingsRow(icon: "message.circle", title: settings.localizedString("chatSettings"), color: .blue)
                    }
                }
            }
            .navigationTitle(settings.localizedString("settings"))
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
                .frame(width: 32)
            
            Text(title)
                .font(.system(size: 17))
            
            Spacer()
        }
    }
}

// Profile View
struct ProfileView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var name = ""
    @State private var username = ""
    @State private var bio = "Hey there! I'm using Telegram"
    @State private var isSaving = false
    @State private var showSaveSuccess = false
    
    var avatarColor: Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .red, .cyan, .indigo]
        let hash = abs(settings.userPhone.hashValue)
        return colors[hash % colors.count]
    }
    
    var body: some View {
        List {
            Section {
                HStack {
                    ZStack {
                        Circle()
                            .fill(avatarColor)
                            .frame(width: 80, height: 80)
                        
                        if name.isEmpty {
                            Image(systemName: "person.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 40))
                        } else {
                            Text(String(name.prefix(2)).uppercased())
                                .foregroundColor(.white)
                                .font(.system(size: 32, weight: .medium))
                        }
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }
            
            Section {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.gray)
                        .frame(width: 24)
                    Text("Имя")
                        .foregroundColor(.gray)
                        .frame(width: 80, alignment: .leading)
                    TextField("Имя", text: $name)
                        .multilineTextAlignment(.trailing)
                }
                
                HStack {
                    Image(systemName: "at")
                        .foregroundColor(.gray)
                        .frame(width: 24)
                    Text("Username")
                        .foregroundColor(.gray)
                        .frame(width: 80, alignment: .leading)
                    TextField("username", text: $username)
                        .multilineTextAlignment(.trailing)
                        .autocapitalization(.none)
                }
                
                HStack {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.gray)
                        .frame(width: 24)
                    Text("Телефон")
                        .foregroundColor(.gray)
                        .frame(width: 80, alignment: .leading)
                    Spacer()
                    Text(settings.userPhone)
                        .foregroundColor(.primary)
                }
            }
            
            Section {
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "text.alignleft")
                            .foregroundColor(.gray)
                        Text("О себе")
                            .foregroundColor(.gray)
                            .font(.system(size: 13))
                    }
                    TextEditor(text: $bio)
                        .frame(height: 60)
                }
            }
            
            Section {
                Button(action: saveProfile) {
                    HStack {
                        Spacer()
                        if isSaving {
                            ProgressView()
                        } else {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Сохранить")
                            }
                            .foregroundColor(.blue)
                        }
                        Spacer()
                    }
                }
                .disabled(isSaving)
            }
            
            if showSaveSuccess {
                Section {
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Профиль обновлен")
                            .foregroundColor(.green)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle(settings.localizedString("profile"))
        .onAppear {
            name = settings.userName
            username = settings.userUsername
        }
    }
    
    func saveProfile() {
        isSaving = true
        showSaveSuccess = false
        
        settings.updateProfile(name: name, username: username) { success in
            isSaving = false
            if success {
                showSaveSuccess = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showSaveSuccess = false
                }
            }
        }
    }
}

// Privacy View
struct PrivacyView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var showPhoneNumber = true
    @State private var showLastSeen = true
    @State private var showProfilePhoto = true
    
    var body: some View {
        List {
            Section(header: Text("WHO CAN SEE MY")) {
                Toggle("Phone Number", isOn: $showPhoneNumber)
                Toggle("Last Seen", isOn: $showLastSeen)
                Toggle("Profile Photo", isOn: $showProfilePhoto)
            }
            
            Section(header: Text("SECURITY")) {
                NavigationLink("Two-Step Verification") {
                    Text("Two-Step Verification Settings")
                }
                NavigationLink("Active Sessions") {
                    Text("Active Sessions")
                }
            }
            
            Section(header: Text("PRIVACY")) {
                NavigationLink("Blocked Users") {
                    Text("Blocked Users List")
                }
                Toggle("Read Receipts", isOn: .constant(true))
            }
        }
        .navigationTitle(settings.localizedString("privacy"))
    }
}

// Appearance View
struct AppearanceView: View {
    @EnvironmentObject var settings: AppSettings
    
    var body: some View {
        List {
            Section(header: Text(settings.localizedString("themes"))) {
                Button(action: { settings.theme = "light" }) {
                    HStack {
                        Text(settings.localizedString("lightTheme"))
                        Spacer()
                        if settings.theme == "light" {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Button(action: { settings.theme = "dark" }) {
                    HStack {
                        Text(settings.localizedString("darkTheme"))
                        Spacer()
                        if settings.theme == "dark" {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Button(action: { settings.theme = "system" }) {
                    HStack {
                        Text(settings.localizedString("systemTheme"))
                        Spacer()
                        if settings.theme == "system" {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle(settings.localizedString("appearance"))
    }
}

// Language View
struct LanguageView: View {
    @EnvironmentObject var settings: AppSettings
    
    var body: some View {
        List {
            Button(action: { settings.language = "en" }) {
                HStack {
                    Text("English")
                    Spacer()
                    if settings.language == "en" {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Button(action: { settings.language = "ru" }) {
                HStack {
                    Text("Русский")
                    Spacer()
                    if settings.language == "ru" {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .navigationTitle(settings.localizedString("language"))
    }
}

// Chat Settings View
struct ChatSettingsView: View {
    @EnvironmentObject var settings: AppSettings
    
    var body: some View {
        List {
            Section(header: Text(settings.localizedString("background"))) {
                Button(action: { settings.chatBackground = "default" }) {
                    HStack {
                        Text("Default")
                        Spacer()
                        if settings.chatBackground == "default" {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Button(action: { settings.chatBackground = "gradient" }) {
                    HStack {
                        Text("Gradient")
                        Spacer()
                        if settings.chatBackground == "gradient" {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Button(action: { settings.chatBackground = "pattern" }) {
                    HStack {
                        Text("Pattern")
                        Spacer()
                        if settings.chatBackground == "pattern" {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle(settings.localizedString("chatSettings"))
    }
}

// Stickers View
struct StickersView: View {
    @EnvironmentObject var settings: AppSettings
    
    var body: some View {
        List {
            Section(header: Text("MY STICKERS")) {
                ForEach(["😀", "😂", "❤️", "👍", "🔥", "🎉"], id: \.self) { emoji in
                    HStack {
                        Text(emoji)
                            .font(.system(size: 40))
                        Text("Sticker Pack")
                        Spacer()
                    }
                }
            }
            
            Section {
                Button("Add Stickers") {
                    // Add stickers action
                }
            }
        }
        .navigationTitle(settings.localizedString("stickers"))
    }
}

// Other placeholder views
struct AccountView: View {
    var body: some View {
        List {
            Text("Account Settings")
        }
        .navigationTitle("Account")
    }
}

struct NotificationsView: View {
    var body: some View {
        List {
            Toggle("Show Notifications", isOn: .constant(true))
            Toggle("Show Preview", isOn: .constant(true))
            Toggle("Sound", isOn: .constant(true))
        }
        .navigationTitle("Notifications")
    }
}

struct DataView: View {
    var body: some View {
        List {
            Text("Storage Usage")
            Text("Network Usage")
            Text("Auto-Download")
        }
        .navigationTitle("Data and Storage")
    }
}
