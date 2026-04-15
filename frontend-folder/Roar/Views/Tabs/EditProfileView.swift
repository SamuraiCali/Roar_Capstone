import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Binding var currentUser: User?
    @Environment(\.presentationMode) var presentationMode

    @StateObject private var uploadService = UploadService()

    @State private var newUsername: String = ""
    @State private var newBio: String = ""

    // Image state
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var profileImage: UIImage?

    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            Form {

                // MARK: - Profile Image
                Section(header: Text("Profile Picture")) {
                    VStack(spacing: 12) {

                        if let profileImage = profileImage {
                            Image(uiImage: profileImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 90, height: 90)
                                .clipShape(Circle())
                        } else if let user = currentUser, let urlString = currentUser?.profileImageUrl,
                                  let url = URL(string: urlString) {
                            let _ = user.profileImageUpdated
                            

                                   AsyncImage(url: url) { phase in
                                       switch phase {
                                       case .empty:
                                           ProgressView()
                                               .frame(width: 100, height: 100)

                                       case .success(let image):
                                           image
                                               .resizable()
                                               .scaledToFill()
                                               .frame(width: 100, height: 100)
                                               .clipShape(Circle())

                                       case .failure(_):
                                           Image(systemName: "person.crop.circle.fill")
                                               .resizable()
                                               .foregroundColor(.white)
                                               .frame(width: 100, height: 100)
                                               .clipShape(Circle())

                                       @unknown default:
                                           EmptyView()
                                       }
                                   }

                               } else {
                                   Circle()
                                       .fill(Color.gray.opacity(0.3))
                                        .frame(width: 90, height: 90)
                                        .overlay(Text("Add"))
                            
                                }

                        if uploadService.isUploading {
                            ProgressView(value: uploadService.uploadProgress)
                        }

                        PhotosPicker(
                            selection: $selectedItem,
                            matching: .images
                        ) {
                            Text("Change Photo")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                // MARK: - Profile Info
                Section(header: Text("Profile Information")) {
                    TextField("Username", text: $newUsername)
                        .autocapitalization(.none)

                    Text("Bio")
                    TextEditor(text: $newBio)
                        .frame(height: 100)
                        
                }

                // MARK: - Errors
                if let error = errorMessage ?? uploadService.uploadError {
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
                .disabled(uploadService.isUploading)
            )

            .onAppear {
                if let user = currentUser {
                    newUsername = user.username
                    newBio = ""
                }
            }

            // MARK: - Image selection
            .onChange(of: selectedItem) { newItem in
                guard let newItem else { return }
                Task {
                    await loadSelectedImage(from: newItem)
                }
            }
        }
    }
}

extension EditProfileView {
    
    struct UploadResponse: Codable {
        let uploadUrl: String
        let key: String
    }
    
    private func uploadProfileImage() async -> String? {
        guard let data = selectedImageData else {
            print("Error formatting image url")
            return nil
        }
        do {
            print("Attempting to upload profile image")
            
            let key = try await uploadService.uploadProfileImage(imageData: data)
            print("Saved Profile Image: \(key)")
            return key
            
            
        } catch {
            print("Error uploading profile image")
        }
        return nil
    }
    
    private func saveProfile() {
        
        Task {
            do {
                let _ = await uploadProfileImage()
                
                if let user = currentUser {

                    var updatedUser = user

                    updatedUser.profileImageUpdated = (updatedUser.profileImageUpdated ?? 0) + 1

                    await MainActor.run {
                        currentUser = updatedUser

                    }

                }
                
                print("TODO: SAVE BIO TO USER")
                
            } catch {
                print("Error saving profile")
            }
        }
        
    }
    
    private func loadSelectedImage(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data) else {
                return
            }
            
            await MainActor.run {
                self.selectedImageData = data
                self.profileImage = uiImage
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load image"
                print("Failed to load image")
            }
        }
    }
}
