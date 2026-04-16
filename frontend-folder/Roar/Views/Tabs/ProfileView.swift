import SwiftUI

struct UserProfile: Codable {
    let id: Int
    let username: String
    let profile_image_key: String?
    let follower_count: Int
    let following_count: Int
    let is_followed: Bool
    let videos: [Video]
}

struct Video: Codable {
    let video_id: Int
    let title: String
    let key: String
    let description: String
    let created_at: String
}

struct ProfileView: View {
    @State private var currentUser: User?
    @State private var userPosts: [Post] = []
    
    @State private var followersCount = 0
    @State private var followingCount = 0
    
    @State private var isLoading = true
    @State private var showingEditProfile = false
    
    @StateObject var session = SessionManager.shared
    
    var profileImageURL: String {
        guard let key = currentUser?.profileImageKey else { return "" }

        let url = "\(S3_BASE_URL)/\(key)?v=\(Date().timeIntervalSince1970)"

//        if let currentUser = SessionManager.shared.currentUser,
//           currentUser.username == post.username {
//            url += "?v=\(currentUser.profileImageUpdated ?? 0)"
//        }

        return url
    }
    
    
    let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        ProgressView()
                            .padding(.top, 50)
                    } else {
                        // Profile Header
                        ZStack {
                            Circle()
                                    .fill(Color.roarBlue)
                                    .frame(width: 100, height: 100)
                                    .overlay(Circle().stroke(Color.roarGold, lineWidth: 3))
                                    .shadow(radius: 5)
                            if let user = session.currentUser, let url = URL(string: user.imageUrlWithVersion ?? "") {
                                AvatarView(url: url, width: 100, height: 100)
                                        .id(url.absoluteString)

                                    
                                } else {
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .foregroundColor(.gray)
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())

                                }
                        }
                        .padding(.top, 20)
                        
                        Text(currentUser?.username ?? "Me")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Welcome to Roar! Update your bio soon.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            showingEditProfile = true
                        }) {
                            Text("Edit Profile")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 8)
                                .background(Color.roarBlue)
                                .cornerRadius(20)
                        }
                        
                        // Stats
                        HStack(spacing: 40) {
                            VStack {
                                Text("\(followersCount)")
                                    .font(.headline)
                                Text("Followers")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            VStack {
                                Text("\(followingCount)")
                                    .font(.headline)
                                Text("Following")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            VStack {
                                Text("\(userPosts.count)") // Pending integration
                                    .font(.headline)
                                Text("Posts")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 10)
                        
                        Divider()
                        
                        ScrollView {
                            if isLoading {
                                ProgressView()
                                    .padding(.top, 50)
                            } else {
                                if userPosts.isEmpty {
                                    Text("User has no posts.")
                                        .foregroundColor(.gray)
                                        .padding(.top, 50)
                                } else {
                                    LazyVGrid(columns: columns, spacing: 2) {
                                        ForEach(userPosts) { post in
                                            NavigationLink(destination: ExploreFeedWrapper(posts: userPosts, initialPostID: post.id)) {
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
            .navigationTitle("Profile")
            .navigationBarItems(trailing:
                Button(action: signOut) {
                    Text("Sign Out")
                        .foregroundColor(.red)
                }
            )
        }
        .sheet(isPresented: $showingEditProfile) {
//            EditProfileView(currentUser: $currentUser)
            EditProfileView(currentUser: $session.currentUser)

        }
        .onAppear {
            
            fetchData()
        }
    }
    
    private func fetchData() {
        Task {
            isLoading = true
            do {
                if let me = SessionManager.shared.currentUser {
                    await MainActor.run { self.currentUser = me }
                    let profileData = try await APIClient.shared.get(endpoint: "/profile/\(me.username)", responseType: UserProfile.self)
                    print("ProfileView: \(profileData.username), key = \(profileData.profile_image_key ?? "NULL")")
                    let posts = try await APIClient.shared.get(endpoint: "/videos/user/\(me.id)", responseType: [Post].self)
                    
                    
                    await MainActor.run {
                        self.followersCount = profileData.follower_count
                        self.followingCount = profileData.following_count
                        self.currentUser?.profileImageKey = profileData.profile_image_key
                        self.userPosts = posts
                    }
                }
            } catch {
                print("Failed to fetch profile: \(error)")
            }
            await MainActor.run { isLoading = false }
        }
    }
    
    private func signOut() {
        SessionManager.shared.clearSession()
        // Ensure App resets to AuthView by clearing userDefaults and dismissing
    }

}
