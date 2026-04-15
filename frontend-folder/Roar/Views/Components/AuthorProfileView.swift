import SwiftUI

//struct FollowCountResponse: Decodable {
//    let follower_count: Int
//}

struct EmptyRequest: Encodable {}

struct AuthorProfileView: View {
    // Changed this to use username since that's what backend relies on
    let username: String
    
    @State private var followersCount = 0
    @State private var followingCount = 0
    @State private var posts: [Post] = []
    @State private var isFollowing = false
    @State private var profileImageUrl: String?
    
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
                    if let urlString = profileImageUrl, let url = URL(string: urlString + "?v=\(Date().timeIntervalSince1970)") {
                        
                        
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 100, height: 100)

                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())

                            case .failure(_):
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .foregroundColor(.white)
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())

                            @unknown default:
                                EmptyView()
                            }
                        }

                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .foregroundColor(.white)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                        
                        
                    }
                    
                    Text("@\(username)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    if let currentUser = SessionManager.shared.currentUser, currentUser.username != username {
                        Button(action: {
                            Task {
                                if isFollowing {
                                    unfollowUser()
                                } else {
                                    followUser()
                                }
                            }
                        }) {
                            Text(isFollowing ? "Following" : "Follow")
                                .font(.headline)
                                .foregroundColor(isFollowing ? .black : .white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                .background(isFollowing ? Color.roarGold : Color.roarBlue)
                                .cornerRadius(10)
                        }
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
                            Text("\(posts.count)") // Backend user posts route pending
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
                    self.isFollowing = profileData.is_followed
                    self.posts = posts
                    if let key = profileData.profile_image_key {
                        print("Get Profile Data: \(key)")
                        self.profileImageUrl = "\(S3_BASE_URL)/\(key)"
                    }
                    
                    self.isLoading = false
                }
            } catch {
                print("Failed to fetch author profile stats: \(error)")
                await MainActor.run { isLoading = false }
            }
        }
    }
    
    private func followUser() {
        Task {
            do {
                _ = try await APIClient.shared.post(endpoint: "/users/\(username)/follow", body: EmptyRequest(), responseType: EmptyResponse.self)
                
                await MainActor.run {
                    isFollowing = true
                    followersCount += 1
                }
                
            } catch {
                print("Failed to follow user \(username)")
            }
        }
    }
    
    private func unfollowUser() {
        Task {
            do {
                _ = try await APIClient.shared.delete(endpoint: "/users/\(username)/follow", body: EmptyRequest(), responseType: EmptyResponse.self)
                
                await MainActor.run {
                    isFollowing = false
                    followersCount -= 1
                }
                
            } catch {
                print("Failed to unfollow user \(username)")
            }
        }
    }
}

