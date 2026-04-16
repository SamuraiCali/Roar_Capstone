import SwiftUI

struct ContentView: View {
    @State private var isSignedIn = false
    @State private var isCheckingSession = true
    @StateObject private var session = SessionManager.shared
    
    var body: some View {
        ZStack {
            if isCheckingSession {
                ProgressView("Checking Session...")
            } else if session.isSignedIn {
                MainTabView()
            } else {
                AuthView()
            }
        }
        .onAppear {
            Task {
                await checkSession()
            }
        }
    }
    
    func checkSession() async {
        if UserDefaults.standard.string(forKey: "auth_token") != nil {
            await SessionManager.shared.loadCurrentUser()
        }
        isCheckingSession = false
    }
}
