// swiftlint:disable all
@preconcurrency import Amplify
import Foundation

extension Comment {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case content
    case user
    case post
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let comment = Comment.keys
    
    model.authRules = [
      rule(allow: .public, provider: .apiKey, operations: [.read]),
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "Comments"
    model.syncPluralName = "Comments"
    
    model.attributes(
      .primaryKey(fields: [comment.id])
    )
    
    model.fields(
      .field(comment.id, is: .required, ofType: .string),
      .field(comment.content, is: .required, ofType: .string),
      .belongsTo(comment.user, is: .optional, ofType: User.self, targetNames: ["userId"]),
      .belongsTo(comment.post, is: .optional, ofType: Post.self, targetNames: ["postId"]),
      .field(comment.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(comment.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<Comment> {
      public nonisolated override init(name: String = "root", isCollection: Bool = false, parent: PropertyPath? = nil) {
        super.init(name: name, isCollection: isCollection, parent: parent)
      }
    }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Comment: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == Comment {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var content: FieldPath<String>   {
      string("content") 
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