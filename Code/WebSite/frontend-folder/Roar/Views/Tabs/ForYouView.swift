import SwiftUI
@preconcurrency import Amplify
internal import AWSPluginsCore

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
            let request = GraphQLRequest<Post>.list(Post.self)
            let result = try await Amplify.API.query(request: request)
            switch result {
            case .success(let postsList):
                print("Successfully retrieved \(postsList.count) posts")
                self.posts = Array(postsList)
                self.isLoading = false
                self.errorMessage = nil
            case .failure(let error):
                print("Got failed result with \(error)")
                self.isLoading = false
            }
        } catch {
            print("Failed to query posts - \(error)")
            self.isLoading = false
            self.errorMessage = error.localizedDescription
        }
    }
}
