import SwiftUI
@preconcurrency import Amplify
internal import AWSPluginsCore

struct AuthorProfileView: View {
    let userID: String
    
    @State private var author: User?
    @State private var authorPosts: [Post] = []
    
    @State private var followersCount = 0
    @State private var followingCount = 0
    
    @State private var isLoading = true
    
    let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if isLoading {
                    ProgressView()
                        .padding(.top, 50)
                } else if let author = author {
                    // Profile Header
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 100, height: 100)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .shadow(radius: 5)
                        .padding(.top, 20)
                    
                    Text("@\(author.username)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    if let bio = author.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Stats
                    HStack(spacing: 40) {
                        VStack {
                            Text("\(followersCount)")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Followers")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        VStack {
                            Text("\(followingCount)")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Following")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        VStack {
                            Text("\(authorPosts.count)")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Posts")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Divider().background(Color.gray)
                    
                    // User's Posts Grid
                    if authorPosts.isEmpty {
                        Text("No posts yet.")
                            .foregroundColor(.gray)
                            .padding(.top, 40)
                    } else {
                        LazyVGrid(columns: columns, spacing: 2) {
                            ForEach(authorPosts, id: \.id) { post in
                                NavigationLink(destination: ExploreFeedWrapper(posts: authorPosts, initialPostID: post.id)) {
                                    ExploreGridCell(post: post)
                                }
                            }
                        }
                    }
                } else {
                    Text("User not found.")
                        .foregroundColor(.gray)
                        .padding(.top, 50)
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle(author?.username ?? "Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchData()
        }
    }
    
    private func fetchData() {
        Task {
            isLoading = true
            do {
                // Fetch User
                let userRequest = GraphQLRequest<User>.get(User.self, byId: userID)
                let userResult = try await Amplify.API.query(request: userRequest)
                if case .success(let fetchedUser) = userResult {
                    await MainActor.run { self.author = fetchedUser }
                }
                
                // Fetch Posts
                let postPredicate = Post.keys.author == userID
                let postRequest = GraphQLRequest<Post>.list(Post.self, where: postPredicate)
                let postResult = try await Amplify.API.query(request: postRequest)
                if case .success(let fetchedPosts) = postResult {
                    await MainActor.run { self.authorPosts = Array(fetchedPosts) }
                }
                
                // Fetch Followers
                let followersPredicate = Follow.keys.following == userID
                let followersRequest = GraphQLRequest<Follow>.list(Follow.self, where: followersPredicate)
                let followersResult = try await Amplify.API.query(request: followersRequest)
                if case .success(let fetchedFollowers) = followersResult {
                    await MainActor.run { self.followersCount = fetchedFollowers.count }
                }
                
                // Fetch Following
                let followingPredicate = Follow.keys.follower == userID
                let followingRequest = GraphQLRequest<Follow>.list(Follow.self, where: followingPredicate)
                let followingResult = try await Amplify.API.query(request: followingRequest)
                if case .success(let fetchedFollowing) = followingResult {
                    await MainActor.run { self.followingCount = fetchedFollowing.count }
                }
                
            } catch {
                print("Failed to fetch author profile: \(error)")
            }
            await MainActor.run { isLoading = false }
        }
    }
}
