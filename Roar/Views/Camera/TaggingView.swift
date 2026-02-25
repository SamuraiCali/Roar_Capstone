import SwiftUI
import AVKit

struct TaggingView: View {
    let videoURL: URL
    @StateObject private var uploadService = UploadService()
    
    @State private var selectedSport = "Football"
    @State private var videoTitle = ""
    @Environment(\.presentationMode) var presentationMode
    
    let sports = ["Football", "Basketball", "Soccer", "Baseball", "Volleyball"]
    
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
                    Text("Tag Your Roar")
                        .font(.title2)
                        .bold()
                    
                    TextField("Video Title", text: $videoTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Picker("Sport", selection: $selectedSport) {
                        ForEach(sports, id: \.self) { sport in
                            Text(sport).tag(sport)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
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
                    .disabled(videoTitle.isEmpty)
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
                    team: "", // Deprecated locally, pending backend schema removal
                    sport: selectedSport,
                    description: videoTitle
                )
                // Dismiss on success
                presentationMode.wrappedValue.dismiss()
            } catch {
                print("Upload failed")
            }
        }
    }
}
