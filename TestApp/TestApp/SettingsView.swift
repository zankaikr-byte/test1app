import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            List {
                // Profile section
                Section {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 64, height: 64)
                            .overlay(
                                Text("ME")
                                    .foregroundColor(.white)
                                    .font(.system(size: 24, weight: .medium))
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("My Name")
                                .font(.system(size: 20, weight: .semibold))
                            Text("+1 234 567 8900")
                                .font(.system(size: 15))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                // Account section
                Section {
                    SettingsRow(icon: "person.circle", title: "Account", color: .blue)
                    SettingsRow(icon: "lock.circle", title: "Privacy and Security", color: .gray)
                    SettingsRow(icon: "bell.circle", title: "Notifications", color: .red)
                    SettingsRow(icon: "tray.circle", title: "Data and Storage", color: .green)
                }
                
                // Appearance section
                Section {
                    SettingsRow(icon: "paintbrush.circle", title: "Appearance", color: .cyan)
                    SettingsRow(icon: "globe", title: "Language", color: .orange)
                    SettingsRow(icon: "sticker.circle", title: "Stickers", color: .purple)
                }
                
                // Support section
                Section {
                    SettingsRow(icon: "questionmark.circle", title: "Ask a Question", color: .blue)
                    SettingsRow(icon: "exclamationmark.circle", title: "Telegram FAQ", color: .orange)
                    SettingsRow(icon: "shield.circle", title: "Privacy Policy", color: .gray)
                }
            }
            .navigationTitle("Settings")
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
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray)
        }
    }
}
