import SwiftUI
import Amplify

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
        Task {
            do {
                let session = try await Amplify.Auth.fetchAuthSession()
                DispatchQueue.main.async {
                    self.isSignedIn = session.isSignedIn
                    self.isCheckingSession = false
                }
                
                if session.isSignedIn {
                    await MockDataGenerator.generateMockUsersAndRelationships()
                }
            } catch {
                print("Error checking session: \(error)")
                DispatchQueue.main.async {
                    self.isSignedIn = false
                    self.isCheckingSession = false
                }
            }
        }
    }
}
