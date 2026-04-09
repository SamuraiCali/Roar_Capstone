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
            checkSession()
        }
    }
    
    func checkSession() {
        // If there's a token, consider them signed in for now
        // A more robust checking mechanism would ping `/api/protected`
        if UserDefaults.standard.string(forKey: "auth_token") != nil {
            isSignedIn = true
        } else {
            isSignedIn = false
        }
        isCheckingSession = false
    }
}
