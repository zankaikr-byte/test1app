import SwiftUI

class AppSettings: ObservableObject {
    @Published var language: String = "ru"
    @Published var theme: String = "system"
    @Published var chatBackground: String = "default"
    
    // Authentication
    @Published var isAuthenticated: Bool = false
    @Published var userPhone: String = ""
    @Published var userName: String = ""
    @Published var userUsername: String = ""
    @Published var userId: String = ""
    @Published var telegramId: String = ""
    
    func updateProfile(name: String, username: String, completion: @escaping (Bool) -> Void) {
        NetworkManager.shared.updateProfile(phone: userPhone, name: name, username: username) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.userName = name
                    self.userUsername = username
                    completion(true)
                case .failure:
                    completion(false)
                }
            }
        }
    }
    
    func localizedString(_ key: String) -> String {
        let translations: [String: [String: String]] = [
            "ru": [
                "chats": "Чаты",
                "contacts": "Контакты",
                "settings": "Настройки",
                "search": "Поиск",
                "edit": "Изменить",
                "account": "Аккаунт",
                "privacy": "Приватность",
                "notifications": "Уведомления",
                "data": "Данные",
                "appearance": "Оформление",
                "language": "Язык",
                "stickers": "Стикеры",
                "profile": "Профиль",
                "phone": "Телефон",
                "username": "Имя пользователя",
                "bio": "О себе",
                "chatSettings": "Настройки чата",
                "background": "Фон чата",
                "themes": "Темы",
                "lightTheme": "Светлая",
                "darkTheme": "Темная",
                "systemTheme": "Системная"
            ],
            "en": [
                "chats": "Chats",
                "contacts": "Contacts",
                "settings": "Settings",
                "search": "Search",
                "edit": "Edit",
                "account": "Account",
                "privacy": "Privacy and Security",
                "notifications": "Notifications",
                "data": "Data and Storage",
                "appearance": "Appearance",
                "language": "Language",
                "stickers": "Stickers",
                "profile": "Profile",
                "phone": "Phone",
                "username": "Username",
                "bio": "Bio",
                "chatSettings": "Chat Settings",
                "background": "Chat Background",
                "themes": "Themes",
                "lightTheme": "Light",
                "darkTheme": "Dark",
                "systemTheme": "System"
            ]
        ]
        return translations[language]?[key] ?? key
    }
}
