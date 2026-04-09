import SwiftUI
@preconcurrency import Amplify
@preconcurrency internal import AWSPluginsCore

struct CommentUIModel: Identifiable {
    let id: String
    let content: String
    let username: String
}

struct CommentSheetView: View {
    let post: Post
    @Binding var commentCount: Int
    
    @State private var comments: [CommentUIModel] = []
    @State private var newCommentText: String = ""
    @State private var isLoading = true
    @State private var currentUserId: String?
    
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
                            Text(comment.username)
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
                let user = try await Amplify.Auth.getCurrentUser()
                await MainActor.run { self.currentUserId = user.userId }
                
                // Fetch comments for this post
                let postPredicate = Comment.keys.post == post.id
                let request = GraphQLRequest<Comment>.list(Comment.self, where: postPredicate)
                let result = try await Amplify.API.query(request: request)
                
                switch result {
                case .success(let fetchedComments):
                    var mappedComments: [CommentUIModel] = []
                    for comment in fetchedComments {
                        let username = (try? await comment.user?.username) ?? "Unknown User"
                        mappedComments.append(CommentUIModel(id: comment.id, content: comment.content, username: username))
                    }
                    let finalComments = mappedComments
                    await MainActor.run {
                        self.comments = finalComments
                        self.commentCount = self.comments.count
                        self.isLoading = false
                    }
                case .failure(let error):
                    print("Failed to fetch comments: \(error)")
                    await MainActor.run { self.isLoading = false }
                }
            } catch {
                print("Error getting user or comments: \(error)")
                await MainActor.run { self.isLoading = false }
            }
        }
    }
    
    private func postComment() {
        guard let uid = currentUserId, !newCommentText.isEmpty else { return }
        
        let contentToPost = newCommentText
        let dummyUser = User(id: uid, username: "")
        let dummyPost = Post(id: post.id, description: "")
        let newComment = Comment(content: contentToPost, user: dummyUser, post: dummyPost)
        
        // Optimistic UI update
        // We assume current user's username is what they set in their profile,
        // but since we only have their ID here easily, we'll placeholder it as "Me" until refresh,
        // or we could fetch the user model. For real-time feel, "Me" works or fetch it in `fetchComments`.
        let optimisticUI = CommentUIModel(id: UUID().uuidString, content: contentToPost, username: "Me")
        comments.append(optimisticUI)
        newCommentText = ""
        commentCount += 1
        
        Task {
            do {
                let result = try await Amplify.API.mutate(request: .create(newComment))
                switch result {
                case .success(_):
                    print("Comment created successfully")
                case .failure(let error):
                    print("GraphQL error creating comment: \(error)")
                }
            } catch {
                print("Error creating comment: \(error)")
            }
        }
    }
}
