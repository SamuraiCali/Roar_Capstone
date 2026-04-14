import Foundation

public struct Comment: Codable, Identifiable, Equatable, Hashable {
    public let id: Int
    public let userId: Int
    public let videoId: Int
    public let content: String
    public let parentCommentId: Int?
    public let createdAt: String
    
    // Additional properties we'll ensure the backend provides/maps
    public let username: String?
    public let replyCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case videoId = "video_id"
        case content
        case parentCommentId = "parent_comment_id"
        case createdAt = "created_at"
        case username
        case replyCount = "reply_count"
    }
}
