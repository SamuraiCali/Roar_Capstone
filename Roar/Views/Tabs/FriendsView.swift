import SwiftUI
@preconcurrency import Amplify
@preconcurrency internal import AWSPluginsCore

struct FriendsView: View {
    @State private var users: [User] = []
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var currentUserId: String?
    @State private var followingIds: Set<String> = []
    
    var filteredUsers: [User] {
        if searchText.isEmpty {
            return users
        } else {
            return users.filter { $0.username.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search users by username...", text: $searchText)
                        .autocapitalization(.none)
                }
                .padding(10)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .padding(.horizontal)
                
                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if filteredUsers.isEmpty {
                    Spacer()
                    Text("No users found.")
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    List(filteredUsers, id: \.id) { user in
                        NavigationLink(destination: AuthorProfileView(userID: user.id)) {
                            HStack {
                                Circle()
                                    .fill(Color.roarBlue)
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.white)
                                    )
                                
                                VStack(alignment: .leading) {
                                    Text("@\(user.username)")
                                        .font(.headline)
                                    if let bio = user.bio {
                                        Text(bio)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .lineLimit(1)
                                    }
                                }
                                
                                Spacer()
                                
                                // Follow Toggle Button
                                if user.id != currentUserId {
                                    let isFollowing = followingIds.contains(user.id)
                                    Button(action: {
                                        toggleFollow(targetUserId: user.id, isFollowing: isFollowing)
                                    }) {
                                        Text(isFollowing ? "Following" : "Follow")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(isFollowing ? .black : .white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(isFollowing ? Color.gray.opacity(0.3) : Color.roarBlue)
                                            .cornerRadius(20)
                                    }
                                    .buttonStyle(PlainButtonStyle()) // Prevent list row highlight when tapping button
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        await fetchFollowing()
                        await fetchUsers()
                    }
                }
            }
            .navigationTitle("Friends")
        }
        .onAppear {
            Task {
                await fetchFollowing()
                await fetchUsers()
            }
        }
    }
    
    private func fetchUsers() async {
        await MainActor.run { isLoading = true }
        do {
            let request = GraphQLRequest<User>.list(User.self)
            let result = try await Amplify.API.query(request: request)
            if case .success(let fetchedUsers) = result {
                await MainActor.run {
                    self.users = Array(fetchedUsers)
                    self.isLoading = false
                }
            }
        } catch {
            print("Failed to fetch users: \(error)")
            await MainActor.run { isLoading = false }
        }
    }
    
    private func fetchFollowing() async {
        do {
            let user = try await Amplify.Auth.getCurrentUser()
            await MainActor.run { self.currentUserId = user.userId }
            
            let followingPredicate = Follow.keys.follower == user.userId
            let followingRequest = GraphQLRequest<Follow>.list(Follow.self, where: followingPredicate)
            let followingResult = try await Amplify.API.query(request: followingRequest)
            if case .success(let fetchedFollowing) = followingResult {
                var ids: [String] = []
                for follow in fetchedFollowing {
                    if let followingUser = try? await follow.following {
                        ids.append(followingUser.id)
                    }
                }
                await MainActor.run { self.followingIds = Set(ids) }
            }
        } catch {
            print("Failed to fetch current user or following IDs: \(error)")
        }
    }
    
    private func toggleFollow(targetUserId: String, isFollowing: Bool) {
        guard let currentUid = currentUserId else { return }
        
        Task {
            if isFollowing {
                // Determine Follow ID to delete
                // Normally we'd fetch this exact follow record to delete it, but an easy MVP way 
                // is to just optimistic UI remove it from the Set, then let backend settle.
                // We actually need the Follow record's ID to delete it via Datastore/API... 
                // We'll query it first, then delete.
                await MainActor.run { followingIds.remove(targetUserId) }
                
                do {
                    let p1 = Follow.keys.follower == currentUid
                    let p2 = Follow.keys.following == targetUserId
                    let request = GraphQLRequest<Follow>.list(Follow.self, where: p1 && p2)
                    let result = try await Amplify.API.query(request: request)
                    if case .success(let follows) = result, let followRecord = follows.first {
                        try await Amplify.API.mutate(request: .delete(followRecord))
                    }
                } catch {
                    print("Unfollow failed: \(error)")
                    await MainActor.run { followingIds.insert(targetUserId) }
                }
                
            } else {
                // Optimistic UI update
                await MainActor.run { followingIds.insert(targetUserId) }
                
                let dummyFollower = User(id: currentUid, username: "")
                let dummyFollowing = User(id: targetUserId, username: "")
                let newFollow = Follow(follower: dummyFollower, following: dummyFollowing)
                do {
                    try await Amplify.API.mutate(request: .create(newFollow))
                } catch {
                    print("Follow failed: \(error)")
                    await MainActor.run { followingIds.remove(targetUserId) }
                }
            }
        }
    }
}
