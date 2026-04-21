import SwiftUI
@preconcurrency import Amplify
@preconcurrency internal import AWSPluginsCore

struct FeedCell: View {
    let post: Post
    @Binding var isPlaying: Bool
    
    @Environment(\.selectedTab) var selectedTab
    @Environment(\.owningTab) var owningTab
    
    @State private var isLiked = false
    @State private var currentLikes: Int = 0
    @State private var currentUserId: String?
    @State private var showingComments = false
    @State private var currentComments: Int = 0
    @State private var authorId: String?
    @State private var authorUsername: String = "roar_creator"
    @State private var isPausedByUser = false
    
    var body: some View {
        ZStack {
            // 1. Full Screen Video Background
            Color.black
                .edgesIgnoringSafeArea(.all)
            
            VideoPlayerView(videoKey: post.videoURL, isPlaying: Binding(
                get: { isPlaying && !isPausedByUser && selectedTab == owningTab && !showingComments },
                set: { _ in }
            ))
            .edgesIgnoringSafeArea(.all)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Invisible touch surface to intercept taps from UIKit AVPlayerLayer
            Color.white.opacity(0.001)
                .edgesIgnoringSafeArea(.all)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onTapGesture {
                    withAnimation {
                        isPausedByUser.toggle()
                    }
                }
            
            // 2. Play/Pause Overlay
            if isPausedByUser {
                Image(systemName: "play.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white.opacity(0.8))
                    .shadow(radius: 10)
                    .allowsHitTesting(false)
            }
            
            // 3. UI Overlays
            VStack {
                Spacer() // Push to bottom
                
                HStack(alignment: .bottom) {
                    // Left Column: User Info & Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("@\(authorUsername)")
                            .font(.headline)
                            .foregroundColor(.white)
                            .shadow(radius: 1)
                        
                        Text(post.description)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .shadow(radius: 1)
                        
                        // Tags
                        HStack {
                            if let team = post.teamTag, !team.isEmpty {
                                Text("#\(team)")
                            }
                            if let sport = post.sportTag, !sport.isEmpty {
                                Text("#\(sport)")
                            }
                        }
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(radius: 1)
                    }
                    .padding(.leading, 16)
                    .padding(.bottom, 90)
                    
                    Spacer()
                    
                    // Right Column: Action Buttons
                    VStack(spacing: 24) {
                        // Profile Pic Placeholder
                        if let aid = authorId, !aid.isEmpty {
                            NavigationLink(destination: AuthorProfileView(userID: aid)) {
                                ZStack {
                                    Circle()
                                        .fill(Color.gray)
                                        .frame(width: 48, height: 48)
                                        .overlay(Circle().stroke(Color.white, lineWidth: 1))
                                    
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .foregroundColor(.white)
                                        .frame(width: 48, height: 48)
                                }
                            }
                        } else {
                            ZStack {
                                Circle()
                                    .fill(Color.gray)
                                    .frame(width: 48, height: 48)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 1))
                                
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundColor(.white)
                                    .frame(width: 48, height: 48)
                            }
                        }
                        
                        // Like Button
                        VStack(spacing: 4) {
                            Button(action: {
                                toggleLike()
                            }) {
                                Image(systemName: isLiked ? "heart.fill" : "heart")
                                    .font(.title)
                                    .foregroundColor(isLiked ? .red : .white)
                                    .shadow(radius: 1)
                            }
                            Text("\(currentLikes)")
                                .font(.caption)
                                .foregroundColor(.white)
                                .shadow(radius: 1)
                        }
                        
                        // Comment Button
                        VStack(spacing: 4) {
                            Button(action: {
                                showingComments.toggle()
                            }) {
                                Image(systemName: "bubble.right.fill")
                                    .font(.title)
                                    .foregroundColor(.white)
                                    .shadow(radius: 1)
                            }
                            Text("\(currentComments)")
                                .font(.caption)
                                .foregroundColor(.white)
                                .shadow(radius: 1)
                        }
                        
                        // Share Button
                        VStack(spacing: 4) {
                            Button(action: {}) {
                                Image(systemName: "arrowshape.turn.up.right.fill")
                                    .font(.title)
                                    .foregroundColor(.white)
                                    .shadow(radius: 1)
                            }
                            Text("Share")
                                .font(.caption)
                                .foregroundColor(.white)
                                .shadow(radius: 1)
                        }
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 90)
                }
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.6), Color.clear]),
                    startPoint: .bottom,
                    endPoint: .center
                )
            )
        }
        .sheet(isPresented: $showingComments) {
            CommentSheetView(post: post, commentCount: $currentComments)
        }
        .onAppear {
            currentLikes = post.likes ?? 0
            checkIfLiked()
            fetchAuthorId()
            fetchCommentCount()
            isPausedByUser = false // Auto resume when appearing if it was active
        }
        .onDisappear {
            isPausedByUser = true // Force pause when swiping away to profile or explore
        }
    }
    
    private func fetchAuthorId() {
        Task {
            if let user = try? await post.author {
                await MainActor.run { 
                    self.authorId = user.id 
                    self.authorUsername = user.username
                }
            }
        }
    }
    
    private func checkIfLiked() {
        Task {
            do {
                let user = try await Amplify.Auth.getCurrentUser()
                await MainActor.run { self.currentUserId = user.userId }
                
                // For MVP, we'll try to just query if there's a Like record where postId == post.id and userId == user.userId
                // Since Amplify Data Gen 2 list filters can be tricky, we'll just check it locally if needed,
                // or just rely on the toggle for now. (Assume false initially if not cached)
            } catch {
                print("Failed to get current user: \(error)")
            }
        }
    }
    
    private func toggleLike() {
        // Optimistic UI update
        isLiked.toggle()
        currentLikes += isLiked ? 1 : -1
        
        Task {
            guard let uid = currentUserId else { return }
            do {
                if isLiked {
                    // Create Like record
                    let dummyUser = User(id: uid, username: "")
                    let dummyPost = Post(id: post.id, description: "")
                    let likeRecord = Like(user: dummyUser, post: dummyPost)
                    try await Amplify.API.mutate(request: .create(likeRecord))
                    
                    // Increment Post likes count
                    var updatedPost = post
                    updatedPost.likes = currentLikes
                    try await Amplify.API.mutate(request: .update(updatedPost))
                } else {
                    // MVP un-like feature relies on finding the specific like record. 
                    // To keep things swift, we just decrement the post count.
                    var updatedPost = post
                    updatedPost.likes = currentLikes
                    try await Amplify.API.mutate(request: .update(updatedPost))
                }
            } catch {
                print("Like mutation failed: \(error)")
                await MainActor.run {
                    isLiked.toggle()
                    currentLikes += isLiked ? 1 : -1
                }
            }
        }
    }
    
    private func fetchCommentCount() {
        Task {
            do {
                let commentsPredicate = Comment.keys.post == post.id
                let request = GraphQLRequest<Comment>.list(Comment.self, where: commentsPredicate)
                let result = try await Amplify.API.query(request: request)
                if case .success(let fetchedComments) = result {
                    await MainActor.run { self.currentComments = fetchedComments.count }
                }
            } catch {
                print("Failed to fetch comment count: \(error)")
            }
        }
    }
}
