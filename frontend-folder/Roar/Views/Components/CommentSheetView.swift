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
                }
                else {
                    List(topLevelComments) { comment in
                        HStack(alignment: .top, spacing: 12) {
                            
                            if let key = comment.profileImageKey,
//                               let url = URL(string: "\(S3_BASE_URL)/\(key)?v=\(Date().timeIntervalSince1970)") {
                               //cache all users but the currently logged in user
                               let url = URL(string: "\(S3_BASE_URL)/\(key)?v=\(comment.userId == SessionManager.shared.currentUser?.id ?? 0 ? Date().timeIntervalSince1970 : 1)") {
                                    AvatarView(url: url)
                                } else {
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
                                    
                                    HStack {
                                        Text("\(timeAgoString(from: comment.createdAt))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
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
                                    }
                                    
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
                                    VStack(alignment: .leading, spacing: 4) {//spacing 8
                                        ForEach(replies(for: comment.id)) { reply in
                                            HStack(alignment: .top) {//spacing 4
                                                if let key = reply.profileImageKey, let url = URL(string: "\(S3_BASE_URL)/\(key)?v=\(Date().timeIntervalSince1970)") {
                                                    
                                                    AvatarView(url: url)
                                                } else {
                                                    Image(systemName: "person.crop.circle.fill")
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: 40, height: 40)
                                                        .foregroundColor(.gray)
                                                
                                                    
                                                }

                                            VStack(alignment: .leading, spacing: 4) {

                                                    Text(reply.username ?? "Unknown User")
                                                        .font(.body)
                                                        .foregroundColor(.gray)
                                                    
                                                    HStack {
                                                        
                                                        Text(reply.content)
                                                            .font(.body)
                                                        
                                                        Spacer()
                                                        
                                                        LikeButtonView(isLikedLocal: likedComments.contains(reply.id), isLikedServer: reply.isLiked, likeCount: reply.likeCount) {
                                                            toggleLike(for: reply.id)
                                                        }
                                                        
                                                    }
                                                    Text("\(timeAgoString(from: reply.createdAt))")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                
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
                    .id(comments.count)
                }
                
                Divider()
                
                //was Hstack
                HStack {
                    if let replyingComment = replyingTo {
                        VStack {
                            HStack {
                                Spacer()
                                
                                Button("Cancel") {
                                    replyingTo = nil
                                    replyText = ""
                                    isReplyFocused = false
                                }
                                .font(.caption)
                                
                            }
                            HStack {
                                TextField("Replying to user \(replyingComment.username ?? "")", text: $replyText)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .focused($isReplyFocused)
                                
                                Button(action: sendReply) {
                                    Image(systemName: "paperplane.fill")
                                        .foregroundColor(replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .roarBlue)
                                }
                            }
                        }
                        
                    } else {
                        TextField("Add a comment...", text: $newCommentText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button(action: postComment) {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .roarBlue)
                        }
                        .disabled(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
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
    
    private func sendReply() {
        Task {
            do {
                guard let parent = replyingTo else { return }
                let text = replyText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { return }
                
                let req = PostCommentRequest(content: text, parent_comment_id: parent.id)
                let response = try await APIClient.shared.post(endpoint: "/videos/\(post.id)/comments", body: req, responseType: PostCommentResponse.self)
                
                var newComm = response.comment
                if newComm.username == nil, let currentUsr = SessionManager.shared.currentUser {
                    newComm = Comment(id: newComm.id, userId: newComm.userId, videoId: newComm.videoId, content: newComm.content, parentCommentId: newComm.parentCommentId, likeCount: newComm.likeCount, isLiked: newComm.isLiked, profileImageKey: currentUsr.profileImageKey, createdAt: newComm.createdAt, username: currentUsr.username, replyCount: newComm.replyCount)
                }
                
//                replyingTo = nil
//                replyText = ""
//                isReplyFocused = false
                
                await MainActor.run {
                    replyingTo = nil
                    replyText = ""
                    isReplyFocused = false
                    print("New reply username: \(newComm.username ?? "NULL"), key: \(newComm.profileImageKey ?? "NULL")")
                    
                    var newComments = self.comments
                    newComments.insert(newComm, at: 0)
                    self.comments = newComments
                    self.commentCount += 1
                    for (idx, comm) in comments.enumerated() {
                        if comm.id == parent.id {
                            comments[idx].replyCount = comments[idx].replyCount ?? 0 + 1
                        }
                    }
                }
                
            } catch {
                print("Error sending reply")
            }
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
                    newComm = Comment(id: newComm.id, userId: newComm.userId, videoId: newComm.videoId, content: newComm.content, parentCommentId: newComm.parentCommentId, likeCount: newComm.likeCount, isLiked: newComm.isLiked, profileImageKey: currentUsr.profileImageKey, createdAt: newComm.createdAt, username: currentUsr.username, replyCount: newComm.replyCount)
                }
                
                await MainActor.run {
                    print("New comment username: \(newComm.username ?? "NULL"), key: \(newComm.profileImageKey ?? "NULL")")
                    var newComments = self.comments
                    newComments.insert(newComm, at: 0)
                    self.comments = newComments
                    self.commentCount += 1
                }
            } catch {
                print("Error creating comment: \(error)")
            }
        }
    }
    private func timeAgoString(from date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        
        if seconds < 60 {
            return "\(seconds)s"
        }
        
        let minutes = seconds / 60
        if minutes < 60 {
            return "\(minutes)m"
        }
        
        let hours = minutes / 60
        if hours < 24 {
            return "\(hours)h"
        }
        
        let days = hours / 24
        return "\(days)d"
    }
}
