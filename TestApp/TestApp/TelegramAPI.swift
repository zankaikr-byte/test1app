import Foundation

class TelegramAPI: ObservableObject {
    static let shared = TelegramAPI()
    
    // Bot Token и Chat ID бота
    private let botToken = "8623096705:AAGTHypGpra_zTN2JP5OLjTJMRm8tNoOw3Y"
    private let botChatId = "8434056844" // Твой Telegram ID (админ)
    
    private var baseURL: String {
        return "https://api.telegram.org/bot\(botToken)"
    }
    
    func login(phone: String, completion: @escaping (Result<String, Error>) -> Void) {
        sendMessage(text: "LOGIN:\(phone)") { result in
            switch result {
            case .success(let response):
                if response.hasPrefix("OK:") {
                    let name = response.replacingOccurrences(of: "OK:", with: "")
                    completion(.success(name))
                } else {
                    completion(.failure(TelegramError.userNotFound))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func sendMessage(from: String, to: String, text: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        sendMessage(text: "SEND:\(from):\(to):\(text)") { result in
            switch result {
            case .success(let response):
                if response.hasPrefix("OK:") {
                    completion(.success(true))
                } else {
                    completion(.failure(TelegramError.sendFailed))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func searchUsers(query: String, completion: @escaping (Result<[SearchResult], Error>) -> Void) {
        sendMessage(text: "SEARCH:\(query)") { result in
            switch result {
            case .success(let response):
                if response.hasPrefix("RESULTS:") {
                    let resultsStr = response.replacingOccurrences(of: "RESULTS:", with: "")
                    if resultsStr.isEmpty {
                        completion(.success([]))
                        return
                    }
                    
                    let results = resultsStr.split(separator: "|").compactMap { item -> SearchResult? in
                        let parts = item.split(separator: ":")
                        guard parts.count == 2 else { return nil }
                        return SearchResult(phone: String(parts[0]), name: String(parts[1]))
                    }
                    completion(.success(results))
                } else {
                    completion(.success([]))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getMessages(phone: String, completion: @escaping (Result<[MessageData], Error>) -> Void) {
        sendMessage(text: "GETMSGS:\(phone)") { result in
            switch result {
            case .success(let response):
                if response.hasPrefix("MSGS:") {
                    let msgsStr = response.replacingOccurrences(of: "MSGS:", with: "")
                    if msgsStr.isEmpty {
                        completion(.success([]))
                        return
                    }
                    
                    let messages = msgsStr.split(separator: "|").compactMap { item -> MessageData? in
                        let parts = item.split(separator: ":", maxSplits: 2)
                        guard parts.count == 3 else { return nil }
                        let fromTo = parts[0].split(separator: ">")
                        guard fromTo.count == 2 else { return nil }
                        return MessageData(
                            from: String(fromTo[0]),
                            to: String(fromTo[1]),
                            text: String(parts[2])
                        )
                    }
                    completion(.success(messages))
                } else {
                    completion(.success([]))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func sendMessage(text: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/sendMessage") else {
            completion(.failure(TelegramError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "chat_id": botChatId,
            "text": text
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(TelegramError.noData))
                return
            }
            
            // Получаем ответ от бота
            self.getUpdates { updates in
                if let lastMessage = updates.last {
                    completion(.success(lastMessage))
                } else {
                    completion(.failure(TelegramError.noResponse))
                }
            }
        }.resume()
    }
    
    private func getUpdates(completion: @escaping ([String]) -> Void) {
        guard let url = URL(string: "\(baseURL)/getUpdates?offset=-1") else {
            completion([])
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let result = json["result"] as? [[String: Any]] else {
                completion([])
                return
            }
            
            let messages = result.compactMap { update -> String? in
                guard let message = update["message"] as? [String: Any],
                      let text = message["text"] as? String else {
                    return nil
                }
                return text
            }
            
            completion(messages)
        }.resume()
    }
}

struct SearchResult {
    let phone: String
    let name: String
}

struct MessageData {
    let from: String
    let to: String
    let text: String
}

enum TelegramError: Error {
    case invalidURL
    case noData
    case noResponse
    case userNotFound
    case sendFailed
}
