import SwiftUI

struct EditProfileView: View {
    @Binding var currentUser: User?
    @Environment(\.presentationMode) var presentationMode
    
    @State private var newUsername: String = ""
    @State private var newBio: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Information")) {
                    TextField("Username", text: $newUsername)
                        .autocapitalization(.none)
                    
                    Text("Bio")
                    TextEditor(text: $newBio)
                        .frame(height: 100)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveProfile()
                }
                .disabled(isSaving)
            )
            .onAppear {
                if let user = currentUser {
                    newUsername = user.username
                    newBio = ""
                }
            }
        }
    }
    
    private func saveProfile() {
        isSaving = true
        errorMessage = nil
        Task {
            do {
                // Backend integration pending for `update_profile`
                await MainActor.run {
                    self.isSaving = false
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}
