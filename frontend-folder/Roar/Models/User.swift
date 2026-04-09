// swiftlint:disable all
@preconcurrency import Amplify
import Foundation

public struct User: @preconcurrency Model, @unchecked Sendable {
  public let id: String
  public var username: String
  public var profilePicURL: String?
  public var bio: String?
  public var posts: List<Post>?
  public var comments: List<Comment>?
  public var likesList: List<Like>?
  public var followers: List<Follow>?
  public var following: List<Follow>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      username: String,
      profilePicURL: String? = nil,
      bio: String? = nil,
      posts: List<Post>? = [],
      comments: List<Comment>? = [],
      likesList: List<Like>? = [],
      followers: List<Follow>? = [],
      following: List<Follow>? = []) {
    self.init(id: id,
      username: username,
      profilePicURL: profilePicURL,
      bio: bio,
      posts: posts,
      comments: comments,
      likesList: likesList,
      followers: followers,
      following: following,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      username: String,
      profilePicURL: String? = nil,
      bio: String? = nil,
      posts: List<Post>? = [],
      comments: List<Comment>? = [],
      likesList: List<Like>? = [],
      followers: List<Follow>? = [],
      following: List<Follow>? = [],
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.username = username
      self.profilePicURL = profilePicURL
      self.bio = bio
      self.posts = posts
      self.comments = comments
      self.likesList = likesList
      self.followers = followers
      self.following = following
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}