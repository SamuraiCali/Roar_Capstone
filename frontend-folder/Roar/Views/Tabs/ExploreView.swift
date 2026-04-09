import SwiftUI
@preconcurrency import Amplify
internal import AWSPluginsCore

struct ExploreView: View {
    @State private var posts: [Post] = []
    @State private var isLoading = false
    @State private var selectedSport: String? = nil
    
    // Computed unique sports for the filter bar
    var availableSports: [String] {
        let allSports = posts.compactMap { $0.sportTag }.filter { !$0.isEmpty }
        return Array(Set(allSports)).sorted()
    }
    
    var filteredPosts: [Post] {
        guard let sport = selectedSport else { return posts }
        return posts.filter { $0.sportTag == sport }
    }
    
    // Grid layout
    let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Bar
                if !availableSports.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterPill(title: "All", isSelected: selectedSport == nil) {
                                selectedSport = nil
                            }
                            
                            ForEach(availableSports, id: \.self) { sport in
                                FilterPill(title: sport, isSelected: selectedSport == sport) {
                                    selectedSport = sport
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    .background(Color.black.opacity(0.8))
                }
                
                // Content Grid
                if isLoading && posts.isEmpty {
                    Spacer()
                    ProgressView("Loading...")
                    Spacer()
                } else if filteredPosts.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("No content found.")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 2) {
                            ForEach(filteredPosts, id: \.id) { post in
                                NavigationLink(destination: ExploreFeedWrapper(posts: filteredPosts, initialPostID: post.id)) {
                                    ExploreGridCell(post: post)
                                }
                            }
                        }
                    }
                    .background(Color.black)
                    .refreshable {
                        await fetchPostsAsync()
                    }
                }
            }
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.black.ignoresSafeArea())
        }
        .onAppear {
            if posts.isEmpty {
                fetchPosts()
            }
        }
        // Force the tint color to be light so Navigation back buttons are visible
        .accentColor(.roarGold)
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
                self.posts = Array(postsList)
                self.isLoading = false
            case .failure(let error):
                print("Explore fetch failed: \(error)")
                self.isLoading = false
            }
        } catch {
            print("Explore query failed: \(error)")
            self.isLoading = false
        }
    }
}

// Subview for the filter buttons
struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.bold)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.roarGold : Color.gray.opacity(0.3))
                .foregroundColor(isSelected ? .black : .white)
                .cornerRadius(20)
        }
    }
}

// Subview for individual grid items showing the thumbnail and likes count
struct ExploreGridCell: View {
    let post: Post
    
    var body: some View {
        GeometryReader { proxy in
            // Make grid items square or slightly tall rectangle (4:5)
            let height = proxy.size.width * 1.5
            
            ZStack(alignment: .bottomLeading) {
                VideoThumbnailView(videoKey: post.videoURL)
                    .frame(width: proxy.size.width, height: height)
                    .clipped()
                
                // Tag Overlay
                HStack(spacing: 4) {
                    Image(systemName: "heart")
                        .font(.caption2)
                    Text("\(post.likes ?? 0)")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .padding(6)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.7), Color.clear]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
            }
            .frame(height: height)
        }
        .aspectRatio(1/1.5, contentMode: .fit) // Force height based on width
    }
}

// Wrapper to launch the feed with a specific list of posts and a starting ID
struct ExploreFeedWrapper: View {
    let posts: [Post]
    let initialPostID: String
    
    var body: some View {
        VerticalFeedView(posts: posts, onRefresh: {
            // Usually we wouldn't fetch *all* posts again from deep inside Explore,
            // but for MVP it satisfies the callback requirement.
        }, activePostID: initialPostID)
        .navigationBarHidden(true)
        .ignoresSafeArea()
    }
}
