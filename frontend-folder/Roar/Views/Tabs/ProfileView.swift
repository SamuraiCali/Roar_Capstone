import SwiftUI
@preconcurrency import Amplify
internal import AWSPluginsCore

struct ProfileView: View {
    @State private var currentUser: User?
    @State private var currentAuthUserId: String?
    @State private var userPosts: [Post] = []
    
    @State private var followersCount = 0
    @State private var followingCount = 0
    
    @State private var isLoading = true
    @State private var showingEditProfile = false
    
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
                            
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .foregroundColor(.white)
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        }
                        .padding(.top, 20)
                        
                        Text(currentUser?.username ?? "Me")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        if let bio = currentUser?.bio, !bio.isEmpty {
                            Text(bio)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        } else {
                            Text("Welcome to Roar! Update your bio soon.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Edit Profile Button (Placeholder MVP)
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
                                Text("\(userPosts.count)")
                                    .font(.headline)
                                Text("Posts")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 10)
                        
                        Divider()
                        
                        // User's Posts Grid
                        if userPosts.isEmpty {
                            Text("You haven't posted any videos yet.")
                                .foregroundColor(.gray)
                                .padding(.top, 40)
                        } else {
                            LazyVGrid(columns: columns, spacing: 2) {
                                ForEach(userPosts, id: \.id) { post in
                                    NavigationLink(destination: ExploreFeedWrapper(posts: userPosts, initialPostID: post.id)) {
                                        ExploreGridCell(post: post)
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            deletePost(postID: post.id)
                                        } label: {
                                            Label("Delete Post", systemImage: "trash")
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
            EditProfileView(currentUser: $currentUser)
        }
        .onAppear {
            fetchData()
        }
    }
    
    private func fetchData() {
        Task {
            isLoading = true
            do {
                let authUser = try await Amplify.Auth.getCurrentUser()
                let uid = authUser.userId
                await MainActor.run { self.currentAuthUserId = uid }
                
                // Fetch User Model
                let userRequest = GraphQLRequest<User>.get(User.self, byId: uid)
                let userResult = try await Amplify.API.query(request: userRequest)
                if case .success(let fetchedUser) = userResult {
                    await MainActor.run { self.currentUser = fetchedUser }
                }
                
                // Fetch Posts
                let postPredicate = Post.keys.author == uid
                let postRequest = GraphQLRequest<Post>.list(Post.self, where: postPredicate)
                let postResult = try await Amplify.API.query(request: postRequest)
                if case .success(let fetchedPosts) = postResult {
                    await MainActor.run { self.userPosts = Array(fetchedPosts) }
                }
                
                // Fetch Followers
                let followersPredicate = Follow.keys.following == uid
                let followersRequest = GraphQLRequest<Follow>.list(Follow.self, where: followersPredicate)
                let followersResult = try await Amplify.API.query(request: followersRequest)
                if case .success(let fetchedFollowers) = followersResult {
                    await MainActor.run { self.followersCount = fetchedFollowers.count }
                }
                
                // Fetch Following
                let followingPredicate = Follow.keys.follower == uid
                let followingRequest = GraphQLRequest<Follow>.list(Follow.self, where: followingPredicate)
                let followingResult = try await Amplify.API.query(request: followingRequest)
                if case .success(let fetchedFollowing) = followingResult {
                    await MainActor.run { self.followingCount = fetchedFollowing.count }
                }
                
            } catch {
                print("Failed to fetch profile: \(error)")
            }
            await MainActor.run { isLoading = false }
        }
    }
    
    private func signOut() {
        Task {
            do {
                _ = try await Amplify.Auth.signOut()
            } catch {
                print("Failed to sign out: \(error)")
            }
        }
    }
    
    private func deletePost(postID: String) {
        Task {
            do {
                let postToDelete = Post(id: postID, description: "") // Minimum required to delete
                try await Amplify.API.mutate(request: .delete(postToDelete))
                
                // Optimistic UI update
                await MainActor.run {
                    self.userPosts.removeAll { $0.id == postID }
                }
            } catch {
                print("Failed to delete post: \(error)")
            }
        }
    }
}
