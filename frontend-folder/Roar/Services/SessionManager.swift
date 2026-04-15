import Foundation
internal import Combine

struct ProtectedResponse: Decodable {
    let message: String
    let user: User_
}

struct User_: Decodable {
    let id: Int
    let username: String
    let imageKey: String?
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
    private let S3_URL = "https://s3-roar-165777654255-us-east-1-an.s3.us-east-1.amazonaws.com"
    
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
            
            let imageKey = response.user.imageKey

            let imageURL: String? = {
                guard let imageKey = imageKey else { return nil }
                return "\(S3_URL)/\(imageKey)"
            }()
            
            self.currentUser = User(id: response.user.id, username: response.user.username, email: nil, profileImageUrl: imageURL, createdAt: nil)
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
