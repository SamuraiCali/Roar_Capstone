import Foundation

public struct User: Codable, Identifiable, Equatable, Hashable {
    public let id: Int
    public let username: String
    public let email: String?
    //computed on login from SessionManager
    public var profileImageUrl: String?
    public var profileImageKey: String?
    public var bio: String?

    public var profileImageUpdated: Int?
    public let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case profileImageUrl
        case profileImageKey = "profile_image_key"
        case createdAt = "created_at"
    }
}

extension User {
    var imageUrlWithVersion: String? {
//        guard let baseUrl = profileImageUrl else { return nil }
        guard let key = profileImageKey else { return nil }

        let version = profileImageUpdated ?? 0
        return "\(S3_BASE_URL)/\(key)?v=\(max(version, 1))"
    }
}
