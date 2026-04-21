// swiftlint:disable all
@preconcurrency import Amplify
import Foundation

extension User {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case username
    case profilePicURL
    case bio
    case posts
    case comments
    case likesList
    case followers
    case following
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let user = User.keys
    
    model.authRules = [
      rule(allow: .public, provider: .apiKey, operations: [.read]),
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "Users"
    model.syncPluralName = "Users"
    
    model.attributes(
      .primaryKey(fields: [user.id])
    )
    
    model.fields(
      .field(user.id, is: .required, ofType: .string),
      .field(user.username, is: .required, ofType: .string),
      .field(user.profilePicURL, is: .optional, ofType: .string),
      .field(user.bio, is: .optional, ofType: .string),
      .hasMany(user.posts, is: .optional, ofType: Post.self, associatedFields: [Post.keys.author]),
      .hasMany(user.comments, is: .optional, ofType: Comment.self, associatedFields: [Comment.keys.user]),
      .hasMany(user.likesList, is: .optional, ofType: Like.self, associatedFields: [Like.keys.user]),
      .hasMany(user.followers, is: .optional, ofType: Follow.self, associatedFields: [Follow.keys.following]),
      .hasMany(user.following, is: .optional, ofType: Follow.self, associatedFields: [Follow.keys.follower]),
      .field(user.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(user.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<User> {
      public nonisolated override init(name: String = "root", isCollection: Bool = false, parent: PropertyPath? = nil) {
        super.init(name: name, isCollection: isCollection, parent: parent)
      }
    }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension User: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == User {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var username: FieldPath<String>   {
      string("username") 
    }
  public var profilePicURL: FieldPath<String>   {
      string("profilePicURL") 
    }
  public var bio: FieldPath<String>   {
      string("bio") 
    }
  public var posts: ModelPath<Post>   {
      Post.Path(name: "posts", isCollection: true, parent: self) 
    }
  public var comments: ModelPath<Comment>   {
      Comment.Path(name: "comments", isCollection: true, parent: self) 
    }
  public var likesList: ModelPath<Like>   {
      Like.Path(name: "likesList", isCollection: true, parent: self) 
    }
  public var followers: ModelPath<Follow>   {
      Follow.Path(name: "followers", isCollection: true, parent: self) 
    }
  public var following: ModelPath<Follow>   {
      Follow.Path(name: "following", isCollection: true, parent: self) 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}