// swiftlint:disable all
@preconcurrency import Amplify
import Foundation

extension Post {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case videoURL
    case teamTag
    case sportTag
    case timestamp
    case description
    case likes
    case author
    case comments
    case likesList
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let post = Post.keys
    
    model.authRules = [
      rule(allow: .public, provider: .apiKey, operations: [.read]),
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "Posts"
    model.syncPluralName = "Posts"
    
    model.attributes(
      .primaryKey(fields: [post.id])
    )
    
    model.fields(
      .field(post.id, is: .required, ofType: .string),
      .field(post.videoURL, is: .optional, ofType: .string),
      .field(post.teamTag, is: .optional, ofType: .string),
      .field(post.sportTag, is: .optional, ofType: .string),
      .field(post.timestamp, is: .optional, ofType: .dateTime),
      .field(post.description, is: .required, ofType: .string),
      .field(post.likes, is: .optional, ofType: .int),
      .belongsTo(post.author, is: .optional, ofType: User.self, targetNames: ["authorId"]),
      .hasMany(post.comments, is: .optional, ofType: Comment.self, associatedFields: [Comment.keys.post]),
      .hasMany(post.likesList, is: .optional, ofType: Like.self, associatedFields: [Like.keys.post]),
      .field(post.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(post.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<Post> {
      public nonisolated override init(name: String = "root", isCollection: Bool = false, parent: PropertyPath? = nil) {
        super.init(name: name, isCollection: isCollection, parent: parent)
      }
    }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Post: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == Post {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var videoURL: FieldPath<String>   {
      string("videoURL") 
    }
  public var teamTag: FieldPath<String>   {
      string("teamTag") 
    }
  public var sportTag: FieldPath<String>   {
      string("sportTag") 
    }
  public var timestamp: FieldPath<Temporal.DateTime>   {
      datetime("timestamp") 
    }
  public var description: FieldPath<String>   {
      string("description") 
    }
  public var likes: FieldPath<Int>   {
      int("likes") 
    }
  public var author: ModelPath<User>   {
      User.Path(name: "author", parent: self) 
    }
  public var comments: ModelPath<Comment>   {
      Comment.Path(name: "comments", isCollection: true, parent: self) 
    }
  public var likesList: ModelPath<Like>   {
      Like.Path(name: "likesList", isCollection: true, parent: self) 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}