// swiftlint:disable all
@preconcurrency import Amplify
import Foundation

extension Like {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case user
    case post
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let like = Like.keys
    
    model.authRules = [
      rule(allow: .public, provider: .apiKey, operations: [.read]),
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "Likes"
    model.syncPluralName = "Likes"
    
    model.attributes(
      .primaryKey(fields: [like.id])
    )
    
    model.fields(
      .field(like.id, is: .required, ofType: .string),
      .belongsTo(like.user, is: .optional, ofType: User.self, targetNames: ["userId"]),
      .belongsTo(like.post, is: .optional, ofType: Post.self, targetNames: ["postId"]),
      .field(like.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(like.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<Like> {
      public nonisolated override init(name: String = "root", isCollection: Bool = false, parent: PropertyPath? = nil) {
        super.init(name: name, isCollection: isCollection, parent: parent)
      }
    }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Like: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == Like {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var user: ModelPath<User>   {
      User.Path(name: "user", parent: self) 
    }
  public var post: ModelPath<Post>   {
      Post.Path(name: "post", parent: self) 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}