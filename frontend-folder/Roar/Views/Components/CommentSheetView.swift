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

struct CommentSheetView: View {
    let post: Post
    @Binding var commentCount: Int
    
    @State private var comments: [Comment] = []
    @State private var newCommentText: String = ""
    @State private var isLoading = true
    
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
                } else {
                    List(comments) { comment in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(comment.username ?? "Unknown User")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)
                            
                            Text(comment.content)
                                .font(.body)
                        }
                        .padding(.vertical, 4)
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
    
    private func fetchComments() {
        Task {
            do {
                let response = try await APIClient.shared.get(endpoint: "/videos/\(post.id)/comments", responseType: GetCommentsResponse.self)
                let fetchedComments = response.comments
                
                await MainActor.run {
                    self.comments = fetchedComments
                    self.commentCount = self.comments.count
                    self.isLoading = false
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
                    newComm = Comment(id: newComm.id, userId: newComm.userId, videoId: newComm.videoId, content: newComm.content, parentCommentId: newComm.parentCommentId, createdAt: newComm.createdAt, username: currentUsr.username, replyCount: newComm.replyCount)
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
