import SwiftUI

struct FollowCountResponse: Decodable {
    let count: Int
}

struct AuthorProfileView: View {
    // Changed this to use username since that's what backend relies on
    let username: String
    
    @State private var followersCount = 0
    @State private var followingCount = 0
    
    @State private var isLoading = true
    
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
                    
                    Text("Posts Grid Integration Pending")
                        .foregroundColor(.gray)
                        .padding(.top, 40)
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
                let followersResp = try await APIClient.shared.get(endpoint: "/users/\(username)/followers/count", responseType: FollowCountResponse.self)
                
                await MainActor.run {
                    self.followersCount = followersResp.count
                    self.isLoading = false
                }
            } catch {
                print("Failed to fetch author profile stats: \(error)")
                await MainActor.run { isLoading = false }
            }
        }
    }
}
