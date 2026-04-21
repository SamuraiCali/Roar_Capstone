import SwiftUI
import Amplify

struct AuthView: View {
    @Binding var isSignedIn: Bool
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    // For Sign Up Verification
    @State private var isVerifying = false
    @State private var confirmationCode = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(isVerifying ? "Verify Email" : (isSignUp ? "Create Account" : "Welcome Back"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.roarBlue)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                if isVerifying {
                    TextField("Confirmation Code", text: $confirmationCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .padding(.horizontal)
                    
                    Button(action: verifyEmail) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Verify")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.roarGold)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                    
                } else {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .padding(.horizontal)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(isSignUp ? .newPassword : .password)
                        .padding(.horizontal)
                    
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
                let userAttributes = [AuthUserAttribute(.email, value: email)]
                let result = try await Amplify.Auth.signUp(
                    username: email,
                    password: password,
                    options: .init(userAttributes: userAttributes)
                )
                await MainActor.run {
                    isLoading = false
                    if !result.isSignUpComplete {
                        isVerifying = true
                        errorMessage = "Please check your email for a code."
                    } else {
                        // Should not happen with default config usually, but handle it
                        signIn()
                    }
                }
            } catch let error as AuthError {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.errorDescription
                    print("SignUp AuthError: \(error.errorDescription)\nRecovery: \(error.recoverySuggestion)")
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func verifyEmail() {
        isLoading = true
        errorMessage = ""
        Task {
            do {
                let result = try await Amplify.Auth.confirmSignUp(for: email, confirmationCode: confirmationCode)
                if result.isSignUpComplete {
                   await MainActor.run {
                       isLoading = false
                       isVerifying = false
                       signIn()
                   }
                }
            } catch let error as AuthError {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.errorDescription
                    print("VerifyEmail AuthError: \(error.errorDescription)\nRecovery: \(error.recoverySuggestion)")
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func signIn() {
        isLoading = true
        errorMessage = ""
        Task {
            do {
                let result = try await Amplify.Auth.signIn(username: email, password: password)
                await MainActor.run {
                    isLoading = false
                    if result.isSignedIn {
                        isSignedIn = true
                    }
                }
            } catch let error as AuthError {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.errorDescription
                    print("SignIn AuthError: \(error.errorDescription)\nRecovery: \(error.recoverySuggestion)")
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
