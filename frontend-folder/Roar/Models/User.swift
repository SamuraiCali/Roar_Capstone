import Foundation

public struct User: Codable, Identifiable, Equatable, Hashable {
    public let id: Int
    public let username: String
    public let email: String?
    public let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case createdAt = "created_at"
    }
}