import Foundation

class TelegramAPI {
    static let shared = TelegramAPI()
    
    // IP твоего компьютера
    private let baseURL = "http://192.168.1.120:5001/api"
    var phoneCodeHash: String?
    
    func sendCode(phoneNumber: String) async throws -> String {
        let url = URL(string: "\(baseURL)/send_code")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["phone": phoneNumber]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(SendCodeResponse.self, from: data)
        
        phoneCodeHash = response.phone_code_hash
        return response.phone_code_hash
    }
    
    func signIn(phoneNumber: String, code: String, phoneCodeHash: String) async throws -> String {
        let url = URL(string: "\(baseURL)/verify_code")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["phone": phoneNumber, "code": code]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(SignInResponse.self, from: data)
        
        return response.session_string
    }
    
    func sendMessage(sessionString: String, botUsername: String, message: String) async throws -> String {
        let url = URL(string: "\(baseURL)/send_message")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "phone": sessionString,
            "bot_username": botUsername,
            "message": message
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(MessageResponse.self, from: data)
        
        return response.response
    }
    
    func checkRequests(phone: String, botUsername: String) async throws -> Int {
        let url = URL(string: "\(baseURL)/check_requests")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["phone": phone, "bot_username": botUsername]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(CheckRequestsResponse.self, from: data)
        
        return response.available_requests
    }
}

struct SendCodeResponse: Codable {
    let phone_code_hash: String
}

struct SignInResponse: Codable {
    let session_string: String
}

struct MessageResponse: Codable {
    let response: String
}

struct CheckRequestsResponse: Codable {
    let available_requests: Int
}

