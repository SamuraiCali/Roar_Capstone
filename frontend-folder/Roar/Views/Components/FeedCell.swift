import SwiftUI

struct EmptyResponse: Codable {}

struct FeedCell: View {
    let post: Post
    @Binding var isPlaying: Bool
    
    @Environment(\.selectedTab) var selectedTab
    @Environment(\.owningTab) var owningTab
    
    @State private var isLiked = false
    @State private var currentLikes: Int = 0
    @State private var showingComments = false
    @State private var currentComments: Int = 0
    @State private var authorId: Int?
    @State private var authorUsername: String = "roar_creator"
    @State private var isPausedByUser = false
    @State private var profileImageUrl: String?
    
    var profileImageURL: String {
        guard let key = post.profileImageKey else { return "" }

        let url = "\(S3_BASE_URL)/\(key)?v=\(Date().timeIntervalSince1970)"

//        if let currentUser = SessionManager.shared.currentUser,
//           currentUser.username == post.username {
//            url += "?v=\(currentUser.profileImageUpdated ?? 0)"
//        }

        return url
    }
    
    var body: some View {
        ZStack {
            // 1. Full Screen Video Background
            Color.black
                .edgesIgnoringSafeArea(.all)
            
            // `videoURL` from AWS Amplify is now `url` from Backend
            VideoPlayerView(videoKey: post.url, isPlaying: Binding(
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
                        
                        Text(post.description ?? "")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .shadow(radius: 1)
                        
                        // Tags currently simplified in the unified model
                        HStack {
                            if let title = post.title, !title.isEmpty {
                                Text("#\(title)")
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
                            NavigationLink(destination: AuthorProfileView(username: authorUsername)) {
                                ZStack {
                                    
//                                    if let key = post.profileImageKey, let url = URL(string: "\(S3_BASE_URL)/\(key)") {
                                    
                                    Circle()
//                                            .fill(Color.gray)
                                            .frame(width: 40, height: 40)
                                            .overlay(Circle().stroke(Color.roarGold, lineWidth: 2))
                                            .shadow(radius: 5)
                                    if !profileImageURL.isEmpty, let url = URL(string: profileImageURL){
                                            AvatarView(url: url)
                                    } else {
                                        Circle()
                                            .fill(Color.gray)
                                            .frame(width: 48, height: 48)
                                            .overlay(Circle().stroke(Color.white, lineWidth: 1))
                                        
                                        Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .foregroundColor(.white)
                                            .frame(width: 48, height: 48)
                
                                            }
//
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
            currentLikes = post.likeCount ?? 0
            currentComments = post.commentCount ?? 0
            isLiked = post.isLiked ?? false
            authorUsername = post.username ?? "roar_creator"
            authorId = post.userId
//            if let key = post.profileImageKey {
//                print("Key: \(key)")
//                profileImageUrl = "\(S3_BASE_URL)/\(key)"
//                print("State url: \(String(describing: profileImageUrl))")
//                print("Local url: \(S3_BASE_URL)/\(key)")
//
//
//            }
            
            isPausedByUser = false // Auto resume when appearing if it was active
        }
        .onDisappear {
            isPausedByUser = true // Force pause when swiping away to profile or explore
        }
    }
    
    private func toggleLike() {
        isLiked.toggle()
        currentLikes += isLiked ? 1 : -1
        
        Task {
            do {
                if isLiked {
                    let _ = try await APIClient.shared.post(endpoint: "/videos/\(post.id)/likes", body: EmptyResponse(), responseType: EmptyResponse.self)
                } else {
                    let _ = try await APIClient.shared.delete(endpoint: "/videos/\(post.id)/likes", body: EmptyResponse(), responseType: EmptyResponse.self)
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
}
