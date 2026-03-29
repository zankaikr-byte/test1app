import Foundation

import Foundation

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    // Список возможных IP адресов для автопоиска
    private let possibleIPs = [
        "192.168.1.120",
        "172.20.10.2",
        "26.72.5.150",
        "192.168.0.100",
        "192.168.1.100",
        "10.0.0.100"
    ]
    
    @Published var currentIP: String = ""
    @Published var isSearching: Bool = false
    
    private var baseURL: String {
        return "http://\(currentIP):5000/api"
    }
    
    func findServer(completion: @escaping (Bool) -> Void) {
        isSearching = true
        
        // Пробуем каждый IP по очереди
        tryNextIP(index: 0, completion: completion)
    }
    
    private func tryNextIP(index: Int, completion: @escaping (Bool) -> Void) {
        guard index < possibleIPs.count else {
            isSearching = false
            completion(false)
            return
        }
        
        let testIP = possibleIPs[index]
        print("🔍 Проверяю IP: \(testIP)")
        
        guard let url = URL(string: "http://\(testIP):5000/api/users") else {
            tryNextIP(index: index + 1, completion: completion)
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 2.0
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil, let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("✅ Сервер найден: \(testIP)")
                DispatchQueue.main.async {
                    self.currentIP = testIP
                    self.isSearching = false
                    completion(true)
                }
            } else {
                print("❌ IP не отвечает: \(testIP)")
                self.tryNextIP(index: index + 1, completion: completion)
            }
        }.resume()
    }
    
    func setCustomIP(_ ip: String) {
        currentIP = ip
    }
    
    func requestCode(phone: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/request_code") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["phone": phone]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let message = json?["message"] as? String {
                    completion(.success(message))
                } else {
                    completion(.failure(NetworkError.userNotFound))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func verifyCode(phone: String, code: String, completion: @escaping (Result<UserData, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/verify_code") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["phone": phone, "code": code]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let name = json?["name"] as? String, let phone = json?["phone"] as? String {
                    let userData = UserData(name: name, phone: phone)
                    completion(.success(userData))
                } else {
                    completion(.failure(NetworkError.invalidCode))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func login(phone: String, completion: @escaping (Result<UserData, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/login") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["phone": phone]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let name = json?["name"] as? String {
                    let userData = UserData(name: name, phone: phone)
                    completion(.success(userData))
                } else {
                    completion(.failure(NetworkError.userNotFound))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func sendMessage(from: String, to: String, text: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/send") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "from": from,
            "to": to,
            "text": text
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(true))
        }.resume()
    }
    
    func searchUsers(query: String, completion: @escaping (Result<[UserData], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/search?q=\(query)") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }
            
            do {
                let users = try JSONDecoder().decode([UserData].self, from: data)
                completion(.success(users))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func getChats(phone: String, completion: @escaping (Result<[ChatData], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/chats?phone=\(phone)") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }
            
            do {
                let chats = try JSONDecoder().decode([ChatData].self, from: data)
                completion(.success(chats))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func getMessages(phone: String, contact: String, completion: @escaping (Result<[MessageData], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/messages?phone=\(phone)&contact=\(contact)") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }
            
            do {
                let messages = try JSONDecoder().decode([MessageData].self, from: data)
                completion(.success(messages))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

struct UserData: Codable {
    let name: String
    let phone: String
}

struct ChatData: Codable {
    let contact_phone: String
    let contact_name: String
    let last_message: String
    let last_message_time: String
    let unread_count: Int
}

struct MessageData: Codable {
    let from: String
    let to: String
    let text: String
    let timestamp: String
}

enum NetworkError: Error {
    case invalidURL
    case noData
    case userNotFound
    case invalidCode
}

