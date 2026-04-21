// swiftlint:disable all
@preconcurrency import Amplify
import Foundation

public struct Post: @preconcurrency Model, @unchecked Sendable {
  public let id: String
  public var videoURL: String?
  public var teamTag: String?
  public var sportTag: String?
  public var timestamp: Temporal.DateTime?
  public var description: String
  public var likes: Int?
  internal var _author: LazyReference<User>
  public var author: User?   {
      get async throws { 
        try await _author.get()
      } 
    }
  public var comments: List<Comment>?
  public var likesList: List<Like>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      videoURL: String? = nil,
      teamTag: String? = nil,
      sportTag: String? = nil,
      timestamp: Temporal.DateTime? = nil,
      description: String,
      likes: Int? = nil,
      author: User? = nil,
      comments: List<Comment>? = [],
      likesList: List<Like>? = []) {
    self.init(id: id,
      videoURL: videoURL,
      teamTag: teamTag,
      sportTag: sportTag,
      timestamp: timestamp,
      description: description,
      likes: likes,
      author: author,
      comments: comments,
      likesList: likesList,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      videoURL: String? = nil,
      teamTag: String? = nil,
      sportTag: String? = nil,
      timestamp: Temporal.DateTime? = nil,
      description: String,
      likes: Int? = nil,
      author: User? = nil,
      comments: List<Comment>? = [],
      likesList: List<Like>? = [],
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.videoURL = videoURL
      self.teamTag = teamTag
      self.sportTag = sportTag
      self.timestamp = timestamp
      self.description = description
      self.likes = likes
      self._author = LazyReference(author)
      self.comments = comments
      self.likesList = likesList
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
  public mutating func setAuthor(_ author: User? = nil) {
    self._author = LazyReference(author)
  }
  public init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      id = try values.decode(String.self, forKey: .id)
      videoURL = try? values.decode(String?.self, forKey: .videoURL)
      teamTag = try? values.decode(String?.self, forKey: .teamTag)
      sportTag = try? values.decode(String?.self, forKey: .sportTag)
      timestamp = try? values.decode(Temporal.DateTime?.self, forKey: .timestamp)
      description = try values.decode(String.self, forKey: .description)
      likes = try? values.decode(Int?.self, forKey: .likes)
      _author = try values.decodeIfPresent(LazyReference<User>.self, forKey: .author) ?? LazyReference(identifiers: nil)
      comments = try values.decodeIfPresent(List<Comment>?.self, forKey: .comments) ?? .init()
      likesList = try values.decodeIfPresent(List<Like>?.self, forKey: .likesList) ?? .init()
      createdAt = try? values.decode(Temporal.DateTime?.self, forKey: .createdAt)
      updatedAt = try? values.decode(Temporal.DateTime?.self, forKey: .updatedAt)
  }
  public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(id, forKey: .id)
      try container.encode(videoURL, forKey: .videoURL)
      try container.encode(teamTag, forKey: .teamTag)
      try container.encode(sportTag, forKey: .sportTag)
      try container.encode(timestamp, forKey: .timestamp)
      try container.encode(description, forKey: .description)
      try container.encode(likes, forKey: .likes)
      try container.encode(_author, forKey: .author)
      try container.encode(comments, forKey: .comments)
      try container.encode(likesList, forKey: .likesList)
      try container.encode(createdAt, forKey: .createdAt)
      try container.encode(updatedAt, forKey: .updatedAt)
  }
}