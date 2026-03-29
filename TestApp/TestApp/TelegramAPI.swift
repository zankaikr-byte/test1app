import Foundation

import Foundation

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    // Замени на IP твоего компьютера где запущен бот
    private let baseURL = "http://26.72.5.150:5000/api"
    
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
}

struct UserData: Codable {
    let name: String
    let phone: String
}

enum NetworkError: Error {
    case invalidURL
    case noData
    case userNotFound
}

