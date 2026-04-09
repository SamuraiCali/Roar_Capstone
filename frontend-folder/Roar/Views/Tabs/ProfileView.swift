import SwiftUI

struct ProfileView: View {
    @State private var currentUser: User?
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
                        
                        Text("Welcome to Roar! Update your bio soon.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
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
                                Text("-") // Pending integration
                                    .font(.headline)
                                Text("Posts")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 10)
                        
                        Divider()
                        
                        Text("Posts Grid Integration Pending")
                            .foregroundColor(.gray)
                            .padding(.top, 40)
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
                if let me = SessionManager.shared.currentUser {
                    await MainActor.run { self.currentUser = me }
                    let followersResp = try await APIClient.shared.get(endpoint: "/users/\(me.username)/followers/count", responseType: FollowCountResponse.self)
                    
                    await MainActor.run {
                        self.followersCount = followersResp.count
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
