import SwiftUI

struct ExploreView: View {
    @State private var searchText = ""
    @State private var searchResults: [Post] = []
    
    // We can show some trending posts directly from backend feed
    @State private var trendingPosts: [Post] = []
    @State private var isLoading = true
    
    let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search users, teams, or sports...", text: $searchText)
                        .autocapitalization(.none)
                        .onChange(of: searchText) { _ in
                            performSearch()
                        }
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResults.removeAll()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(10)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.bottom, 10)
                
                ScrollView {
                    if isLoading {
                        ProgressView()
                            .padding(.top, 50)
                    } else if !searchText.isEmpty {
                        if searchResults.isEmpty {
                            Text("No results found.")
                                .foregroundColor(.gray)
                                .padding(.top, 50)
                        } else {
                            LazyVGrid(columns: columns, spacing: 2) {
                                ForEach(searchResults, id: \.id) { post in
                                    NavigationLink(destination: ExploreFeedWrapper(posts: searchResults, initialPostID: post.id)) {
                                        ExploreGridCell(post: post)
                                    }
                                }
                            }
                        }
                    } else {
                        // Default Trending Feed
                        if trendingPosts.isEmpty {
                            Text("No trending posts at the moment.")
                                .foregroundColor(.gray)
                                .padding(.top, 50)
                        } else {
                            LazyVGrid(columns: columns, spacing: 2) {
                                ForEach(trendingPosts, id: \.id) { post in
                                    NavigationLink(destination: ExploreFeedWrapper(posts: trendingPosts, initialPostID: post.id)) {
                                        ExploreGridCell(post: post)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
//                if trendingPosts.isEmpty {
                //not optimal, but we need to refresh when it fetches stale videos
                    fetchTrending()
//                }
            }
        }
    }
    
    private func fetchTrending() {
        isLoading = true
        Task {
            do {
                let response = try await APIClient.shared.get(endpoint: "/videos", responseType: FeedResponse.self)
                await MainActor.run {
                    self.trendingPosts = response.videos
                    self.isLoading = false
                }
            } catch {
                print("Failed to fetch trending: \(error)")
                await MainActor.run { self.isLoading = false }
            }
        }
    }
    
    private func performSearch() {
        // Debounce logic should go here ideally
        // In local state, we can just filter trending or hit a search endpoint
        let lowercased = searchText.lowercased()
        searchResults = trendingPosts.filter { post in
            let matchTitle = (post.title ?? "").lowercased().contains(lowercased)
            let matchDesc = (post.description ?? "").lowercased().contains(lowercased)
            let matchUser = (post.username ?? "").lowercased().contains(lowercased)
            return matchTitle || matchDesc || matchUser
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
                VideoThumbnailView(videoKey: post.url)
                    .frame(width: proxy.size.width, height: height)
                    .clipped()
                
                // Tag Overlay
                HStack(spacing: 4) {
                    Image(systemName: "heart")
                        .font(.caption2)
                    Text("\(post.likeCount ?? 0)")
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
    let initialPostID: Int
    
    var body: some View {
        VerticalFeedView(posts: posts, onRefresh: {
            // Usually we wouldn't fetch *all* posts again from deep inside Explore,
            // but for MVP it satisfies the callback requirement.
        }, activePostID: initialPostID)
        .navigationBarHidden(true)
        .ignoresSafeArea()
    }
}
