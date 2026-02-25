// swiftlint:disable all
@preconcurrency import Amplify
import Foundation

public struct Follow: @preconcurrency Model, @unchecked Sendable {
  public let id: String
  internal var _follower: LazyReference<User>
  public var follower: User?   {
      get async throws { 
        try await _follower.get()
      } 
    }
  internal var _following: LazyReference<User>
  public var following: User?   {
      get async throws { 
        try await _following.get()
      } 
    }
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      follower: User? = nil,
      following: User? = nil) {
    self.init(id: id,
      follower: follower,
      following: following,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      follower: User? = nil,
      following: User? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self._follower = LazyReference(follower)
      self._following = LazyReference(following)
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
  public mutating func setFollower(_ follower: User? = nil) {
    self._follower = LazyReference(follower)
  }
  public mutating func setFollowing(_ following: User? = nil) {
    self._following = LazyReference(following)
  }
  public init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      id = try values.decode(String.self, forKey: .id)
      _follower = try values.decodeIfPresent(LazyReference<User>.self, forKey: .follower) ?? LazyReference(identifiers: nil)
      _following = try values.decodeIfPresent(LazyReference<User>.self, forKey: .following) ?? LazyReference(identifiers: nil)
      createdAt = try? values.decode(Temporal.DateTime?.self, forKey: .createdAt)
      updatedAt = try? values.decode(Temporal.DateTime?.self, forKey: .updatedAt)
  }
  public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(id, forKey: .id)
      try container.encode(_follower, forKey: .follower)
      try container.encode(_following, forKey: .following)
      try container.encode(createdAt, forKey: .createdAt)
      try container.encode(updatedAt, forKey: .updatedAt)
  }
}