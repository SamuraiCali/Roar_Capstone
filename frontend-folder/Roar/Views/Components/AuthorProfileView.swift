import SwiftUI

struct FollowCountResponse: Decodable {
    let follower_count: Int
}

struct AuthorProfileView: View {
    // Changed this to use username since that's what backend relies on
    let username: String
    
    @State private var followersCount = 0
    @State private var followingCount = 0
    @State private var posts: [Post] = []
    
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
                } else {
                    // Profile Header
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 100, height: 100)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .shadow(radius: 5)
                        .padding(.top, 20)
                    
                    Text("@\(username)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
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
                            Text("-") // Backend user posts route pending
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Posts")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Divider().background(Color.gray)
                    
                    ScrollView {
                        if isLoading {
                            ProgressView()
                                .padding(.top, 50)
                        } else {
                            if posts.isEmpty {
                                Text("User has no posts.")
                                    .foregroundColor(.gray)
                                    .padding(.top, 50)
                            } else {
                                LazyVGrid(columns: columns, spacing: 2) {
                                    ForEach(posts) { post in
                                        NavigationLink(destination: ExploreFeedWrapper(posts: posts, initialPostID: post.id)) {
                                            ExploreGridCell(post: post)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle(username)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchData()
        }
    }
    
    private func fetchData() {
        Task {
            isLoading = true
            do {
                
                let profileData = try await APIClient.shared.get(endpoint: "/profile/\(username)", responseType: UserProfile.self)
                let posts = await APIClient.shared.fetchVideosDetails(videos: profileData.videos)
                
                await MainActor.run {
                    self.followersCount = profileData.follower_count
                    self.followingCount = profileData.following_count
                    self.posts = posts
                    
                    self.isLoading = false
                }
            } catch {
                print("Failed to fetch author profile stats: \(error)")
                await MainActor.run { isLoading = false }
            }
        }
    }
}
