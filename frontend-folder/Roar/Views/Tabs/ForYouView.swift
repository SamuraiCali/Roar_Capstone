import SwiftUI

struct FeedResponse: Decodable {
    let videos: [Post]
}

struct ForYouView: View {
    @State private var posts: [Post] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea() // TikTok style dark background
                
                Group {
                    if isLoading && posts.isEmpty {
                        ProgressView("Loading posts...")
                    } else if let error = errorMessage {
                        VStack {
                            Text("Failed to load posts")
                                .font(.headline)
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                            Button("Retry") {
                                fetchPosts()
                            }
                            .padding()
                        }
                    } else if posts.isEmpty {
                        VStack {
                            Text("No posts available.")
                                .foregroundColor(.secondary)
                            Button("Refresh") {
                                fetchPosts()
                            }
                            .padding()
                        }
                    } else {
                        VerticalFeedView(posts: posts) {
                            await fetchPostsAsync()
                        }
                    }
                }
                .navigationBarHidden(true) // Hide navigation bar for full screen effect
                .onAppear {
                    fetchPosts()
                }
            }
        }
    }

    func fetchPosts() {
        Task {
            await fetchPostsAsync()
        }
    }

    @MainActor
    func fetchPostsAsync() async {
        isLoading = true
        do {
            let response = try await APIClient.shared.get(endpoint: "/videos", responseType: FeedResponse.self)
            self.posts = response.videos
            self.isLoading = false
            self.errorMessage = nil
            print("Successfully retrieved \(self.posts.count) posts from node backend")
        } catch {
            print("Failed to query posts - \(error)")
            self.isLoading = false
            self.errorMessage = error.localizedDescription
        }
    }
}
