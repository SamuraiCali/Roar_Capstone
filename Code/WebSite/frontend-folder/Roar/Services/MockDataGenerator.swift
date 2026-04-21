import Foundation
@preconcurrency import Amplify
@preconcurrency internal import AWSPluginsCore

class MockDataGenerator {
    
    static let fakeUsers = [
        ("user_1_mock_id", "sports_fan99", "Huge fan of basketball and crazy dunks!"),
        ("user_2_mock_id", "college_hoops_insider", "All the latest from the NCAA."),
        ("user_3_mock_id", "touchdown_tommy", "Football is life."),
        ("user_4_mock_id", "soccer_star_22", "Kicking it daily."),
        ("user_5_mock_id", "slam_dunk_king", "Watch me fly!")
    ]
    
    static func generateMockUsersAndRelationships() async {
        print("Starting Mock Data Generation...")
        
        do {
            // 1. Create Mock Users
            for (id, username, bio) in fakeUsers {
                let user = User(id: id, username: username, bio: bio)
                try await Amplify.API.mutate(request: .create(user))
                print("Created mock user: @\(username)")
            }
            
            // 2. We don't automatically create random follows here to keep it clean, 
            // but we ensure the current user (if logged in) has someone to search for.
            
            // To ensure the current authenticated user has an entry in the User table:
            let authUser = try await Amplify.Auth.getCurrentUser()
            // Try fetching first so we don't accidentally overwrite if they edited
            let request = GraphQLRequest<User>.get(User.self, byId: authUser.userId)
            let result = try await Amplify.API.query(request: request)
            
            if case .success(let fetchedUser) = result, fetchedUser == nil {
                // If the user doesn't exist in the database, create them
                let newUser = User(id: authUser.userId, username: authUser.username, bio: "New to Roar!")
                try await Amplify.API.mutate(request: .create(newUser))
                print("Created database entry for current authenticated user.")
            }
            
            print("Finished Mock Data Generation!")
        } catch {
            print("Error generating mock data: \(error)")
        }
    }
}
