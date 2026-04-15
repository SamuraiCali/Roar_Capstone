import Foundation

public struct User: Codable, Identifiable, Equatable, Hashable {
    public let id: Int
    public let username: String
    public let email: String?
    //computed on login from SessionManager
    public let profileImageUrl: String?
    public var profileImageUpdated: Int?
    public let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case profileImageUrl
        case createdAt = "created_at"
    }
}
