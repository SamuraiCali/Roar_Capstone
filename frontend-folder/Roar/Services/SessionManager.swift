import Foundation
//internal import Combine

struct ProtectedResponse: Decodable {
    let message: String
    let user: User_
}

struct User_: Decodable {
    let id: Int
    let username: String
    let iat: Int
    let exp: Int
}

@MainActor
class SessionManager: ObservableObject {
    
    static let shared = SessionManager()
    
    @Published var currentUser: User? = nil
    @Published var token: String? = nil
    
    private let userDefaultsKey = "auth_token"
    private let userKey = "current_user_id"
    
    init() {
        self.token = UserDefaults.standard.string(forKey: userDefaultsKey)
        // Optionally fetch user using token on init if we wanted to
    }
    
    func loadCurrentUser() async {
        do {
            let response = try await APIClient.shared.get(
                endpoint: "/protected",
                responseType: ProtectedResponse.self
            )
            
            self.currentUser = User(id: response.user.id, username: response.user.username, email: nil, createdAt: nil)
        } catch {
            print("Failed to load user:", error)
        }
    }
    
    func saveSession(token: String, user: User) {
        self.token = token
        self.currentUser = user
        UserDefaults.standard.set(token, forKey: userDefaultsKey)
    }
    
    func clearSession() {
        self.token = nil
        self.currentUser = nil
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
}
