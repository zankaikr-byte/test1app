import SwiftUI

struct TelegraphIPLoggerView: View {
    @State private var title = ""
    @State private var author = "Anonymous"
    @State private var description = ""
    @State private var generatedLink = ""
    @State private var webhookURL = ""
    @State private var webhookCheckURL = ""
    @State private var showCopied = false
    @State private var isCreating = false
    @State private var statusMessage = ""
    @State private var logs: [IPLog] = []
    @State private var isMonitoring = false
    @State private var selectedWebhookService = "webhook.site"
    @State private var customWebhookURL = ""
    @State private var showWebhookPicker = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.cyan.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "link.circle.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(.top, 20)
                    
                    Text("Telegraph IP Logger")
                        .font(.system(size: 28, weight: .bold))
                    
                    if generatedLink.isEmpty {
                        // Форма создания
                        VStack(spacing: 16) {
                            Button(action: { showWebhookPicker = true }) {
                                HStack {
                                    Image(systemName: "link.circle")
                                    Text("Webhook: \(selectedWebhookService)")
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                            }
                            .foregroundColor(.primary)
                            
                            if selectedWebhookService == "custom" {
                                TextField("Custom Webhook URL", text: $customWebhookURL)
                                    .padding()
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                                    .autocapitalization(.none)
                            }
                            
                            TextField("Заголовок статьи", text: $title)
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.1), radius: 5)
                            
                            TextField("Автор (по умолчанию Anonymous)", text: $author)
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.1), radius: 5)
                            
                            TextField("Описание/текст статьи", text: $description, axis: .vertical)
                                .lineLimit(3...6)
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.1), radius: 5)
                            
                            Button(action: createTelegraphLogger) {
                                HStack {
                                    if isCreating {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    }
                                    Text(isCreating ? "Создание..." : "Создать статью")
                                }
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .disabled(isCreating || title.isEmpty || description.isEmpty)
                        }
                        .padding()
                        .sheet(isPresented: $showWebhookPicker) {
                            WebhookPickerView(selectedService: $selectedWebhookService)
                        }
                    } else {
                        // Результат
                        VStack(spacing: 16) {
                            VStack(spacing: 12) {
                                Text("✓ Статья создана!")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("URL статьи:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    HStack {
                                        Text(generatedLink)
                                            .font(.system(.caption, design: .monospaced))
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                        
                                        Button(action: {
                                            UIPasteboard.general.string = generatedLink
                                            showCopied = true
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                                showCopied = false
                                            }
                                        }) {
                                            Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.1), radius: 8)
                            
                            // Мониторинг
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Мониторинг визитов")
                                        .font(.headline)
                                    Spacer()
                                    Circle()
                                        .fill(isMonitoring ? Color.green : Color.gray)
                                        .frame(width: 12, height: 12)
                                }
                                
                                Button(action: {
                                    if isMonitoring {
                                        isMonitoring = false
                                    } else {
                                        isMonitoring = true
                                        startMonitoring()
                                    }
                                }) {
                                    Text(isMonitoring ? "Остановить" : "Запустить мониторинг")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(isMonitoring ? Color.red : Color.green)
                                        .cornerRadius(10)
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.1), radius: 8)
                            
                            // Логи
                            if !logs.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Визиты (\(logs.count))")
                                        .font(.headline)
                                    
                                    ForEach(logs) { log in
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                Text("IP: \(log.ip)")
                                                    .font(.system(.body, design: .monospaced))
                                                    .fontWeight(.bold)
                                                Spacer()
                                                Text(log.time)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            if let country = log.country {
                                                Text("🌍 \(country)")
                                                    .font(.caption)
                                            }
                                            
                                            if let city = log.city {
                                                Text("🏙️ \(city)")
                                                    .font(.caption)
                                            }
                                            
                                            Text(log.userAgent)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                                .lineLimit(2)
                                        }
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .cornerRadius(10)
                                    }
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.1), radius: 8)
                            }
                            
                            Button("Создать новую статью") {
                                generatedLink = ""
                                webhookURL = ""
                                webhookCheckURL = ""
                                logs = []
                                isMonitoring = false
                                title = ""
                                description = ""
                            }
                            .foregroundColor(.blue)
                            .padding()
                        }
                        .padding()
                    }
                    
                    if !statusMessage.isEmpty {
                        Text(statusMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func createTelegraphLogger() {
        isCreating = true
        statusMessage = "Создание webhook..."
        
        Task {
            do {
                if selectedWebhookService == "custom" {
                    webhookURL = customWebhookURL
                    webhookCheckURL = customWebhookURL
                } else if selectedWebhookService == "discord" {
                    webhookURL = customWebhookURL
                    webhookCheckURL = ""
                } else {
                    let webhookData = try await createWebhook()
                    webhookURL = "https://webhook.site/\(webhookData.uuid)"
                    webhookCheckURL = "https://webhook.site/token/\(webhookData.uuid)/requests"
                }
                
                statusMessage = "Создание Telegraph аккаунта..."
                
                let accessToken = try await createTelegraphAccount(author: author.isEmpty ? "Anonymous" : author)
                
                statusMessage = "Создание статьи..."
                
                let pageURL = try await createTelegraphPage(
                    accessToken: accessToken,
                    title: title,
                    author: author.isEmpty ? "Anonymous" : author,
                    description: description,
                    webhookURL: webhookURL
                )
                
                await MainActor.run {
                    generatedLink = pageURL
                    isCreating = false
                    statusMessage = "✓ Статья создана!"
                }
            } catch {
                await MainActor.run {
                    isCreating = false
                    statusMessage = "Ошибка: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func startMonitoring() {
        Task {
            while isMonitoring {
                do {
                    let newLogs = try await fetchWebhookLogs(webhookCheckURL: webhookCheckURL)
                    
                    await MainActor.run {
                        for log in newLogs {
                            if !logs.contains(where: { $0.id == log.id }) {
                                logs.insert(log, at: 0)
                            }
                        }
                    }
                    
                    try await Task.sleep(nanoseconds: 5_000_000_000) // 5 секунд
                } catch {
                    await MainActor.run {
                        statusMessage = "Ошибка мониторинга: \(error.localizedDescription)"
                    }
                    try? await Task.sleep(nanoseconds: 10_000_000_000)
                }
            }
        }
    }
    
    func createWebhook() async throws -> WebhookResponse {
        let url = URL(string: "https://webhook.site/token")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(WebhookResponse.self, from: data)
    }
    
    func createTelegraphAccount(author: String) async throws -> String {
        let url = URL(string: "https://api.telegra.ph/createAccount")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "short_name": author,
            "author_name": author
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(TelegraphAccountResponse.self, from: data)
        
        guard response.ok else {
            throw NSError(domain: "Telegraph", code: -1)
        }
        
        return response.result.access_token
    }
    
    func createTelegraphPage(accessToken: String, title: String, author: String, description: String, webhookURL: String) async throws -> String {
        let url = URL(string: "https://api.telegra.ph/createPage")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let timestamp = Int(Date().timeIntervalSince1970)
        let content: [[String: Any]] = [
            ["tag": "p", "children": [description]],
            ["tag": "img", "attrs": ["src": "\(webhookURL)?logger=ip&t=\(timestamp)"]]
        ]
        
        let body: [String: Any] = [
            "access_token": accessToken,
            "title": title,
            "author_name": author,
            "content": content,
            "return_content": false
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(TelegraphPageResponse.self, from: data)
        
        guard response.ok else {
            throw NSError(domain: "Telegraph", code: -1)
        }
        
        return "https://telegra.ph/\(response.result.path)"
    }
    
    func fetchWebhookLogs(webhookCheckURL: String) async throws -> [IPLog] {
        guard let url = URL(string: webhookCheckURL) else { return [] }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(WebhookLogsResponse.self, from: data)
        
        var logs: [IPLog] = []
        for req in response.data {
            // Фильтруем ботов
            let botKeywords = ["bot", "crawler", "spider", "telegram", "discord", "preview", "link", "embed"]
            let isBot = botKeywords.contains { req.user_agent.lowercased().contains($0) }
            
            if !isBot {
                let ipInfo = try? await fetchIPInfo(ip: req.ip)
                logs.append(IPLog(
                    id: req.uuid,
                    ip: req.ip,
                    time: req.created_at,
                    userAgent: req.user_agent,
                    country: ipInfo?.country,
                    city: ipInfo?.city
                ))
            }
        }
        
        return logs
    }
    
    func fetchIPInfo(ip: String) async throws -> IPInfo {
        let url = URL(string: "http://ip-api.com/json/\(ip)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(IPInfo.self, from: data)
    }
}

struct IPLog: Identifiable {
    let id: String
    let ip: String
    let time: String
    let userAgent: String
    let country: String?
    let city: String?
}

struct WebhookResponse: Codable {
    let uuid: String
}

struct TelegraphAccountResponse: Codable {
    let ok: Bool
    let result: TelegraphAccount
}

struct TelegraphAccount: Codable {
    let access_token: String
}

struct TelegraphPageResponse: Codable {
    let ok: Bool
    let result: TelegraphPage
}

struct TelegraphPage: Codable {
    let path: String
}

struct WebhookLogsResponse: Codable {
    let data: [WebhookRequest]
}

struct WebhookRequest: Codable {
    let uuid: String
    let ip: String
    let created_at: String
    let user_agent: String
}

struct IPInfo: Codable {
    let country: String
    let city: String
}

struct WebhookPickerView: View {
    @Binding var selectedService: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Button(action: {
                    selectedService = "webhook.site"
                    dismiss()
                }) {
                    HStack {
                        Text("Webhook.site")
                        Spacer()
                        if selectedService == "webhook.site" {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Button(action: {
                    selectedService = "discord"
                    dismiss()
                }) {
                    HStack {
                        Text("Discord Webhook")
                        Spacer()
                        if selectedService == "discord" {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Button(action: {
                    selectedService = "custom"
                    dismiss()
                }) {
                    HStack {
                        Text("Custom Webhook")
                        Spacer()
                        if selectedService == "custom" {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Выбор Webhook")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
