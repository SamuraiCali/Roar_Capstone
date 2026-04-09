import SwiftUI

struct VerticalFeedView: View {
    let posts: [Post]
    let onRefresh: () async -> Void
    
    // Tracks the ID of the post currently fully visible on screen
    @State var activePostID: Int?
    
    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(posts, id: \.id) { post in
                        PostContainer(post: post, activePostID: $activePostID, containerSize: proxy.size)
                            .containerRelativeFrame(.vertical, alignment: .center)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: $activePostID)
            .scrollTargetBehavior(.paging)
            .ignoresSafeArea()
            .refreshable {
                await onRefresh()
            }
            .onAppear {
                // Autoplay the first video when the feed appears if none is active
                if activePostID == nil {
                    activePostID = posts.first?.id
                }
            }
            .onDisappear {
                // Force pause when leaving nested view
                activePostID = nil
            }
        }
    }
}

struct PostContainer: View {
    let post: Post
    @Binding var activePostID: Int?
    let containerSize: CGSize
    
    var body: some View {
        // Create a dedicated binding that is true ONLY if this specific post's ID matches the active scrolled ID
        let isPlaying = Binding(
            get: { activePostID == post.id },
            set: { _ in } // View shouldn't directly set this via the cell itself
        )
        
        FeedCell(post: post, isPlaying: isPlaying)
            .frame(width: containerSize.width, height: containerSize.height)
            .clipped()
            .id(post.id) // Crucial for scrollPosition tracking
    }
}
