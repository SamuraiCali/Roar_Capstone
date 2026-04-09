import SwiftUI
@preconcurrency import Amplify
import AVFoundation

struct VideoThumbnailView: View {
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
        guard let key = videoKey, !key.isEmpty, thumbnailImage == nil else { return }
        
        isLoading = true
        Task {
            do {
                let url = try await Amplify.Storage.getURL(path: .fromString(key))
                
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
                print("Failed to generate thumbnail for \(key): \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}
