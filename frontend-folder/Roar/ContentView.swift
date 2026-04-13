import SwiftUI

struct ContentView: View {
    @State private var isSignedIn = false
    @State private var isCheckingSession = true
    
    var body: some View {
        ZStack {
            if isCheckingSession {
                ProgressView("Checking Session...")
            } else if isSignedIn {
                MainTabView()
            } else {
                AuthView(isSignedIn: $isSignedIn)
            }
        }
        .onAppear {
            Task {
                await checkSession()
            }
        }
    }
    
    func checkSession() async {
        // A more robust checking mechanism would ping `/api/protected`
        if UserDefaults.standard.string(forKey: "auth_token") != nil {
            await SessionManager.shared.loadCurrentUser()
            isSignedIn = SessionManager.shared.currentUser != nil
        } else {
            isSignedIn = false
        }
        isCheckingSession = false
    }
}
