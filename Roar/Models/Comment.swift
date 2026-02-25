// swiftlint:disable all
@preconcurrency import Amplify
import Foundation

public struct Comment: @preconcurrency Model, @unchecked Sendable {
  public let id: String
  public var content: String
  internal var _user: LazyReference<User>
  public var user: User?   {
      get async throws { 
        try await _user.get()
      } 
    }
  internal var _post: LazyReference<Post>
  public var post: Post?   {
      get async throws { 
        try await _post.get()
      } 
    }
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      content: String,
      user: User? = nil,
      post: Post? = nil) {
    self.init(id: id,
      content: content,
      user: user,
      post: post,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      content: String,
      user: User? = nil,
      post: Post? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.content = content
      self._user = LazyReference(user)
      self._post = LazyReference(post)
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
  public mutating func setUser(_ user: User? = nil) {
    self._user = LazyReference(user)
  }
  public mutating func setPost(_ post: Post? = nil) {
    self._post = LazyReference(post)
  }
  public init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      id = try values.decode(String.self, forKey: .id)
      content = try values.decode(String.self, forKey: .content)
      _user = try values.decodeIfPresent(LazyReference<User>.self, forKey: .user) ?? LazyReference(identifiers: nil)
      _post = try values.decodeIfPresent(LazyReference<Post>.self, forKey: .post) ?? LazyReference(identifiers: nil)
      createdAt = try? values.decode(Temporal.DateTime?.self, forKey: .createdAt)
      updatedAt = try? values.decode(Temporal.DateTime?.self, forKey: .updatedAt)
  }
  public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(id, forKey: .id)
      try container.encode(content, forKey: .content)
      try container.encode(_user, forKey: .user)
      try container.encode(_post, forKey: .post)
      try container.encode(createdAt, forKey: .createdAt)
      try container.encode(updatedAt, forKey: .updatedAt)
  }
}