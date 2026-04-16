import SwiftUI

struct AuthResponse: Codable {
    let message: String
    let user: User
    let token: String
}

struct RegisterRequest: Encodable {
    let username: String
    let email: String
    let password: String
    let sports: [String]
}

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct AuthView: View {
//    @Binding var isSignedIn: Bool
    @State private var isSignUp = false
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var selectedSports: Set<String> = []
    
    let sports = ["Football", "Basketball", "Soccer", "Baseball", "Volleyball", "Other"]
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(isSignUp ? "Create Account" : "Welcome Back")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.roarBlue)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .padding(.horizontal)
                
                if isSignUp {
                    TextField("Username", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.username)
                        .autocapitalization(.none)
                        .padding(.horizontal)
                }
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(isSignUp ? .newPassword : .password)
                    .padding(.horizontal)
                
                if isSignUp {
                    
                    Text("Select the sports you're interested in")
                        .font(.headline)
                        .padding(.horizontal)

                    Text("This helps us personalize your experience.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: columns) {
                        ForEach(sports, id: \.self) { sport in
                            Text(sport)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selectedSports.contains(sport.lowercased()) ? Color.roarGold : Color.gray.opacity(0.2))
                                .foregroundColor(selectedSports.contains(sport.lowercased()) ? .white : .primary)
                                .clipShape(Capsule())
                                .onTapGesture {
                                    if selectedSports.contains(sport.lowercased()) {
                                        selectedSports.remove(sport.lowercased())
                                    } else {
                                        selectedSports.insert(sport.lowercased())
                                    }
                                    print("\(selectedSports)")
                                }
                        }
                    }
              
                }
                
                Button(action: isSignUp ? signUp : signIn) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text(isSignUp ? "Sign Up" : "Sign In")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.roarBlue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                Button(action: { isSignUp.toggle() }) {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.top, 50)
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }
    
    func signUp() {
        isLoading = true
        errorMessage = ""
        Task {
            do {
                let req = RegisterRequest(username: username, email: email, password: password, sports: Array(selectedSports))
                let response = try await APIClient.shared.post(endpoint: "/auth/register", body: req, responseType: AuthResponse.self)
                await MainActor.run {
                    SessionManager.shared.saveSession(token: response.token, user: response.user)
                    isLoading = false
//                    isSignedIn = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func signIn() {
        isLoading = true
        errorMessage = ""
        Task {
            do {
                let req = LoginRequest(email: email, password: password)
                let response = try await APIClient.shared.post(endpoint: "/auth/login", body: req, responseType: AuthResponse.self)
                await MainActor.run {
                    SessionManager.shared.saveSession(token: response.token, user: response.user)
                    isLoading = false
//                    isSignedIn = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}
