import SwiftUI
import AVFoundation

struct VideoThumbnailView: View {
    // This is now effectively the `url` from the backend, not the S3 Key anymore
    let videoKey: String?
    
    @State private var thumbnailImage: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            Color.gray.opacity(0.3)
            
            if let img = thumbnailImage {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                ProgressView()
            } else {
                Image(systemName: "video.fill")
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        guard let keyUrl = videoKey, !keyUrl.isEmpty, let url = URL(string: keyUrl), thumbnailImage == nil else { return }
        
        isLoading = true
        Task {
            do {
                let asset = AVAsset(url: url)
                let generator = AVAssetImageGenerator(asset: asset)
                generator.appliesPreferredTrackTransform = true
                
                // Fetch frame at 0.0 seconds
                let time = CMTime(seconds: 0.0, preferredTimescale: 600)
                let cgImage = try await generator.image(at: time).image
                
                await MainActor.run {
                    self.thumbnailImage = UIImage(cgImage: cgImage)
                    self.isLoading = false
                }
            } catch {
                print("Failed to generate thumbnail for \(keyUrl): \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}
