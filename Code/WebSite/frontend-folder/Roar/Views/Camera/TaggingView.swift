import SwiftUI
import AVKit

struct TaggingView: View {
    let videoURL: URL
    @StateObject private var uploadService = UploadService()
    
    @State private var videoDescription = ""
    @State private var selectedSports: Set<String> = []

    @Environment(\.presentationMode) var presentationMode
    
    let sports = ["Football", "Basketball", "Soccer", "Baseball", "Volleyball", "Other"]
    
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Video Preview Loop
                VideoPlayer(player: AVPlayer(url: videoURL))
                    .frame(height: 300)
                    .cornerRadius(12)
                    .padding()
                
                // Form
                VStack(alignment: .leading, spacing: 15) {
                    Text("Add a description")
                        .font(.title2)
                        .bold()
                    
                    TextField("Video Description", text: $videoDescription)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Text("Tag Your Roar")
                        .font(.title2)
                        .bold()
                    
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
                .padding()
                
                // Upload Button
                if uploadService.isUploading {
                    VStack {
                        ProgressView(value: uploadService.uploadProgress)
                        Text("Uploading... \(Int(uploadService.uploadProgress * 100))%")
                    }
                    .padding()
                } else {
                    Button(action: uploadRoar) {
                        Text("Post Roar")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue) // Roar Blue
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                    .disabled(videoDescription.isEmpty)
                }
                
                if let error = uploadService.uploadError {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("New Post")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func uploadRoar() {
        Task {
            do {
                try await uploadService.uploadVideo(
                    fileURL: videoURL,
                    sports: Array(selectedSports),
                    description: videoDescription
                )
                // Dismiss on success
                presentationMode.wrappedValue.dismiss()
            } catch {
                print("Upload failed")
            }
        }
    }
}
