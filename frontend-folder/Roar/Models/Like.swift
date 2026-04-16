import Foundation

public struct Like: Codable, Identifiable, Equatable, Hashable {
    public let id: Int
    public let userId: Int
    public let videoId: Int
    public let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case videoId = "video_id"
        case createdAt = "created_at"
    }
}