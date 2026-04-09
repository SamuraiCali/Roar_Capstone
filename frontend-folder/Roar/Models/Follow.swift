import Foundation

public struct Follow: Codable, Identifiable, Equatable, Hashable {
    public let id: Int
    public let followerId: Int
    public let followingId: Int
    public let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case followerId = "follower_id"
        case followingId = "following_id"
        case createdAt = "created_at"
    }
}