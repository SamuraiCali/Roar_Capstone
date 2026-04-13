import Foundation
internal import Combine

struct PresignedURLResponse: Decodable {
    let uploadUrl: String
    let key: String
}

struct VideoMetadataRequest: Encodable {
    let key: String
    let title: String?
    let description: String?
    let duration_seconds: Int?
    let width: Int?
    let height: Int?
}

struct VideoMetadataResponse: Decodable {
    let video: Post
}

class UploadService: ObservableObject {
    @Published var uploadProgress: Double = 0.0
    @Published var isUploading = false
    @Published var uploadError: String?
    
    func uploadVideo(fileURL: URL, team: String, sport: String, description: String) async throws {
        await MainActor.run {
            isUploading = true
            uploadProgress = 0
        }
        
        do {
            // 1. Get presigned URL
            let fileName = fileURL.lastPathComponent
            let urlResponse = try await APIClient.shared.get(endpoint: "/videos/presigned-url?fileName=\(fileName)&fileType=video/mp4", responseType: PresignedURLResponse.self)
            
            // 2. Upload file directly via PUT
            var uploadReq = URLRequest(url: URL(string: urlResponse.uploadUrl)!)
            uploadReq.httpMethod = "PUT"
            uploadReq.setValue("video/mp4", forHTTPHeaderField: "Content-Type")
            
            let fileData = try Data(contentsOf: fileURL)
            let (_, urlResponseHTTP) = try await URLSession.shared.upload(for: uploadReq, from: fileData)
            
            if let httpResp = urlResponseHTTP as? HTTPURLResponse, !(200...299).contains(httpResp.statusCode) {
                throw NSError(domain: "UploadError", code: httpResp.statusCode)
            }
            
            await MainActor.run {
                self.uploadProgress = 1.0
            }
            
            // 3. Post metadata
            let metaRequest = VideoMetadataRequest(
                key: urlResponse.key,
                title: team,
                description: description,
                duration_seconds: nil,
                width: nil,
                height: nil
            )
            
            let _ = try await APIClient.shared.post(endpoint: "/videos", body: metaRequest, responseType: VideoMetadataResponse.self)
            
        } catch {
            await MainActor.run {
                self.uploadError = error.localizedDescription
                self.isUploading = false
            }
            throw error
        }
        
        await MainActor.run {
            isUploading = false
        }
    }
}
