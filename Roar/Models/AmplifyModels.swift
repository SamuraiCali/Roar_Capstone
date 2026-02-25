// swiftlint:disable all
@preconcurrency import Amplify
import Foundation

// Contains the set of classes that conforms to the `Model` protocol. 

final public class AmplifyModels: AmplifyModelRegistration {
  public let version: String = "0d81114cf40e92ccd070168a41118a74"
  
  public func registerModels(registry: ModelRegistry.Type) {
    ModelRegistry.register(modelType: User.self)
    ModelRegistry.register(modelType: Post.self)
    ModelRegistry.register(modelType: Like.self)
    ModelRegistry.register(modelType: Comment.self)
    ModelRegistry.register(modelType: Follow.self)
  }
}