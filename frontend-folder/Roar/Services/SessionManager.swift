import Foundation

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
