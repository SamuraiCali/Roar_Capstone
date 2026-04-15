import Foundation

public struct Post: Codable, Identifiable, Equatable, Hashable {
    public let id: Int
    public let userId: Int
    public let key: String
    public let title: String?
    public let description: String?
    public let durationSeconds: Int?
    public let width: Int?
    public let height: Int?
    public let createdAt: String?
    public let url: String?
    
    // Additional properties from feed query
    public let username: String?
    public var likeCount: Int?
    public let commentCount: Int?
    public var isLiked: Bool?
    public let profileImageKey: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case key
        case title
        case description
        case durationSeconds = "duration_seconds"
        case width
        case height
        case createdAt = "created_at"
        case url
        case username
        case likeCount = "like_count"
        case commentCount = "comment_count"
        case isLiked = "is_liked"
        case profileImageKey = "profile_image_key"
    }
}
