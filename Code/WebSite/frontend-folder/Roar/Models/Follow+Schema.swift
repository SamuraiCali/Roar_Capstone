// swiftlint:disable all
@preconcurrency import Amplify
import Foundation

extension Follow {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case follower
    case following
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let follow = Follow.keys
    
    model.authRules = [
      rule(allow: .public, provider: .apiKey, operations: [.read]),
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "Follows"
    model.syncPluralName = "Follows"
    
    model.attributes(
      .primaryKey(fields: [follow.id])
    )
    
    model.fields(
      .field(follow.id, is: .required, ofType: .string),
      .belongsTo(follow.follower, is: .optional, ofType: User.self, targetNames: ["followerId"]),
      .belongsTo(follow.following, is: .optional, ofType: User.self, targetNames: ["followingId"]),
      .field(follow.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(follow.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<Follow> {
      public nonisolated override init(name: String = "root", isCollection: Bool = false, parent: PropertyPath? = nil) {
        super.init(name: name, isCollection: isCollection, parent: parent)
      }
    }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Follow: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == Follow {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var follower: ModelPath<User>   {
      User.Path(name: "follower", parent: self) 
    }
  public var following: ModelPath<User>   {
      User.Path(name: "following", parent: self) 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}