import SwiftUI
@preconcurrency import Amplify
@preconcurrency internal import AWSPluginsCore

struct EditProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var currentUser: User?
    
    @State private var username: String = ""
    @State private var bio: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Information")) {
                    TextField("Username", text: $username)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    TextEditor(text: $bio)
                        .frame(height: 100)
                        .overlay(
                            VStack {
                                if bio.isEmpty {
                                    HStack {
                                        Text("Bio")
                                            .foregroundColor(.gray)
                                            .padding(.top, 8)
                                            .padding(.leading, 4)
                                        Spacer()
                                    }
                                }
                                Spacer()
                            }
                        )
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button(action: saveProfile) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Save").bold()
                    }
                }
                .disabled(isLoading || username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
            .onAppear {
                if let user = currentUser {
                    username = user.username
                    bio = user.bio ?? ""
                }
            }
        }
    }
    
    private func saveProfile() {
        guard var userToUpdate = currentUser else { return }
        
        isLoading = true
        errorMessage = nil
        
        userToUpdate.username = username
        userToUpdate.bio = bio
        
        Task {
            do {
                let result = try await Amplify.API.mutate(request: .update(userToUpdate))
                switch result {
                case .success(let updatedUser):
                    await MainActor.run {
                        self.currentUser = updatedUser
                        self.isLoading = false
                        self.presentationMode.wrappedValue.dismiss()
                    }
                case .failure(let error):
                    await MainActor.run {
                        self.errorMessage = "Failed to update profile: \(error.localizedDescription)"
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Error updating profile: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
}
