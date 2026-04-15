import SwiftUI

struct GetCommentsResponse: Decodable {
    let comments: [Comment]
}

struct PostCommentRequest: Encodable {
    let content: String
    let parent_comment_id: Int?
}

struct PostCommentResponse: Decodable {
    let comment: Comment
}

public let S3_BASE_URL = "https://s3-roar-165777654255-us-east-1-an.s3.us-east-1.amazonaws.com"


struct CommentSheetView: View {
    let post: Post
    @Binding var commentCount: Int
    
    @State private var comments: [Comment] = []
    @State private var newCommentText: String = ""
    @State private var isLoading = true
    @State private var expandedComments: Set<Int> = []
    @State private var likedComments: Set<Int> = []

    
    @State private var replyingTo: Comment? = nil
    @State private var replyText: String = ""
    @FocusState private var isReplyFocused: Bool
    
    private var topLevelComments: [Comment] {
        comments.filter { $0.parentCommentId == nil }
    }

    private var replyCounts: [Int: Int] {
        var counts: [Int: Int] = [:]
        
        for comment in comments {
            if let parentId = comment.parentCommentId {
                counts[parentId, default: 0] += 1
            }
        }
        
        return counts
    }
    
    var body: some View {
        NavigationView {
            
            VStack {
                
                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if comments.isEmpty {
                    Spacer()
                    Text("No comments yet. Be the first!")
                        .foregroundColor(.secondary)
                    Spacer()
                } else if replyingTo != nil {
                    ReplyComposerView(
                        replyingTo: $replyingTo,
                        text: $replyText,
                        isFocused: $isReplyFocused,
                        onSend: sendReply
                    )
                    .transition(.move(edge: .bottom))
                } else {
                    List(topLevelComments) { comment in
                        HStack(alignment: .top, spacing: 12) {
                            
                            if let key = comment.profileImageKey,
                                       let url = URL(string: "\(S3_BASE_URL)/\(key)") {

                                        AsyncImage(url: url) { phase in
                                            switch phase {
                                            case .empty:
                                                ProgressView()
                                                    .frame(width: 40, height: 40)

                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 40, height: 40)
                                                    .clipShape(Circle())

                                            case .failure:
                                                Image(systemName: "person.crop.circle.fill")
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 40, height: 40)
                                                    .foregroundColor(.gray)

                                            @unknown default:
                                                EmptyView()
                                            }
                                        }

                                    } else {
                                        // Default avatar when nil
                                        Image(systemName: "person.crop.circle.fill")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 40, height: 40)
                                            .foregroundColor(.gray)
                                    }
                            
                            
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(comment.username ?? "Unknown User")
                                    .font(.body)
                                
                                    .fontWeight(.semibold)
                                    .foregroundColor(.gray)
                                
                                Text(comment.content)
                                    .font(.body)
                                
                                HStack {
                                    Button {
                                        replyingTo = comment
                                        replyText = ""
                                        isReplyFocused = true
                                    } label: {
                                        Text("Reply")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Spacer()
                                    
                                    LikeButtonView(isLikedLocal: likedComments.contains(comment.id), isLikedServer: comment.isLiked, likeCount: comment.likeCount) {
                                        toggleLike(for: comment.id)
                                    }
                                    
                                }
                                .padding(.top, 2)
                                
                                if let count = comment.replyCount, count > 0 {
                                    Button(action: {
                                        toggleReplies(for: comment.id)
                                    }) {
                                        HStack(spacing: 4) {
                                            Text(expandedComments.contains(comment.id)
                                                 ? "Hide replies"
                                                 : "View \(count) replies")
                                            
                                            Image(systemName: expandedComments.contains(comment.id)
                                                  ? "chevron.up"
                                                  : "chevron.down")
                                        }
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    
                                }
                                
                                if expandedComments.contains(comment.id) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(replies(for: comment.id)) { reply in
                                            VStack(alignment: .leading, spacing: 4) {
                                                
                                                Text(reply.username ?? "Unknown User")
                                                    .font(.body)
                                                    .foregroundColor(.gray)
                                                    .padding(.leading, 12)
                                                
                                                HStack {
                                                    
                                                    Text(reply.content)
                                                        .font(.body)
                                                        .padding(.leading, 12)
                                                    
                                                    Spacer()
                                                    
                                                    LikeButtonView(isLikedLocal: likedComments.contains(reply.id), isLikedServer: reply.isLiked, likeCount: reply.likeCount) {
                                                        toggleLike(for: reply.id)
                                                    }
                                                    
                                                }
                                            }
                                        }
                                    }
                                    .padding(.top, 6)
                                }
                            }
                            .padding(.vertical, 4)
                            
                        }
                    }
                    .listStyle(PlainListStyle())
                }
                
                Divider()
                
                HStack {
                    TextField("Add a comment...", text: $newCommentText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: postComment) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .roarBlue)
                    }
                    .disabled(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            fetchComments()
        }
    }
    
    private func toggleLike(for commentId: Int) {
        Task {
            if likedComments.contains(commentId) {
                print("Attempting to unlike comment \(commentId)")
                await unlikeComment(commentId: commentId)
            } else {
                print("Attempting to like comment \(commentId)")

                await likeComment(commentId: commentId)
            }
        }
    }
    
    private func likeComment(commentId: Int) async {
        do {
            let _ = try await APIClient.shared.post(endpoint: "/videos/comment/\(commentId)/like", body: EmptyRequest(), responseType: EmptyResponse.self)
            likedComments.insert(commentId)
        } catch {
            likedComments.remove(commentId)
            print("Error liking comment \(commentId)")
        }
        
    }
    
    private func unlikeComment(commentId: Int) async {
        do {
            let _ = try await APIClient.shared.delete(endpoint: "/videos/comment/\(commentId)/like", body: EmptyRequest(), responseType: EmptyResponse.self)
            likedComments.remove(commentId)
        } catch {
            likedComments.insert(commentId)
            print("Error unliking comment \(commentId)")
        }
        
    }
    
    private func replies(for commentId: Int) -> [Comment] {
        comments
            .filter { $0.parentCommentId == commentId }
            .sorted { $0.createdAt < $1.createdAt }
    }
    
    private func toggleReplies(for commentId: Int) {
        if expandedComments.contains(commentId) {
            expandedComments.remove(commentId)
        } else {
            expandedComments.insert(commentId)
        }
    }
    
    private func sendReply() async {
        do {
            guard let parent = replyingTo else { return }
            let text = replyText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return }
            
            let req = PostCommentRequest(content: text, parent_comment_id: parent.id)
            let response = try await APIClient.shared.post(endpoint: "/videos/\(post.id)/comments", body: req, responseType: PostCommentResponse.self)
            
            var newComm = response.comment
            if newComm.username == nil, let currentUsr = SessionManager.shared.currentUser {
                newComm = Comment(id: newComm.id, userId: newComm.userId, videoId: newComm.videoId, content: newComm.content, parentCommentId: newComm.parentCommentId, likeCount: newComm.likeCount, isLiked: newComm.isLiked, profileImageKey: newComm.profileImageKey, createdAt: newComm.createdAt, username: currentUsr.username, replyCount: newComm.replyCount)
            }
            
            replyingTo = nil
            replyText = ""
            isReplyFocused = false
            
            await MainActor.run {
                self.comments.insert(newComm, at: 0)
                self.commentCount += 1
            }
            
        } catch {
            print("Error sending reply")
        }
    }
    
    private func fetchComments() {
        Task {
            do {
                let response = try await APIClient.shared.get(endpoint: "/videos/\(post.id)/comments", responseType: GetCommentsResponse.self)
                let fetchedComments = response.comments
                
                await MainActor.run {
                    self.comments = fetchedComments
                    self.commentCount = self.comments.count
                    self.isLoading = false
                    
                    for comment in fetchedComments {
                        if comment.isLiked ?? false {
                            likedComments.insert(comment.id)
                        }
                    }
                }
            } catch {
                print("Error getting user or comments: \(error)")
                await MainActor.run { self.isLoading = false }
            }
        }
    }
    
    private func postComment() {
        if newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return }
        let contentToPost = newCommentText
        newCommentText = ""
        
        Task {
            do {
                let req = PostCommentRequest(content: contentToPost, parent_comment_id: nil)
                let response = try await APIClient.shared.post(endpoint: "/videos/\(post.id)/comments", body: req, responseType: PostCommentResponse.self)
                
                var newComm = response.comment
                // If backend does not immediately return username with the created comment for the optimistic model
                // We'll update it with what we have in SessionManager
                
                if newComm.username == nil, let currentUsr = SessionManager.shared.currentUser {
                    newComm = Comment(id: newComm.id, userId: newComm.userId, videoId: newComm.videoId, content: newComm.content, parentCommentId: newComm.parentCommentId, likeCount: newComm.likeCount, isLiked: newComm.isLiked, profileImageKey: newComm.profileImageKey, createdAt: newComm.createdAt, username: currentUsr.username, replyCount: newComm.replyCount)
                }
                
                await MainActor.run {
                    self.comments.insert(newComm, at: 0)
                    self.commentCount += 1
                }
            } catch {
                print("Error creating comment: \(error)")
            }
        }
    }
}
