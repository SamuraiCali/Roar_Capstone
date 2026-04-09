import SwiftUI

struct FriendsView: View {
    @State private var followingPosts: [Post] = []
    @State private var recommendedUsers: [User] = []
    @State private var isLoading = false
    @State private var currentUserId: Int?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    if isLoading {
                        Spacer()
                        ProgressView("Loading Friends Flow...")
                        Spacer()
                    } else if currentUserId == nil {
                        Spacer()
                        Text("Sign in to see your friends' posts.")
                            .foregroundColor(.secondary)
                        Spacer()
                    } else {
                        Text("Friends Feed Integration Pending")
                            .foregroundColor(.gray)
                            .padding(.top, 40)
                        Spacer()
                    }
                }
            }
            .navigationTitle("Friends")
            .navigationBarHidden(true)
            .onAppear {
                fetchData()
            }
        }
    }
    
    private func fetchData() {
        if let me = SessionManager.shared.currentUser {
            currentUserId = me.id
        }
        isLoading = false
    }
}
