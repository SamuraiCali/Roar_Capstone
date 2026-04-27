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
    let sports: [String]
    let duration_seconds: Int?
    let width: Int?
    let height: Int?
}

struct VideoMetadataResponse: Decodable {
    let video: Post
}

struct BioRequest: Encodable {
    let bio: String
}

class UploadService: ObservableObject {
    @Published var uploadProgress: Double = 0.0
    @Published var isUploading = false
    @Published var uploadError: String?
    
    func uploadVideo(fileURL: URL, sports: [String], description: String) async throws {
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
                title: "",
                description: description,
                sports: sports,
                duration_seconds: nil,
                width: nil,
                height: nil
            )
            
            let _ = try await APIClient.shared.post(endpoint: "/videos", body: metaRequest, responseType: VideoMetadataResponse.self)
            
            await MainActor.run {
                self.isUploading = false
            }
            
        } catch {
            await MainActor.run {
                self.uploadError = error.localizedDescription
                self.isUploading = false
            }
            throw error
        }
    }
    
    func uploadProfileImage(imageData: Data, fileName: String = "avatar.jpg") async throws -> String {
        await MainActor.run {
            isUploading = true
            uploadProgress = 0
            uploadError = nil
        }

        do {
            print("Getting presigned profile image upload URL")
            let urlResponse = try await APIClient.shared.post(
                endpoint: "/profile/avatar?fileName=\(fileName)&fileType=image/jpeg",
                body: EmptyRequest(),
                responseType: PresignedURLResponse.self
            )

            // 2. Upload directly to S3
            print("Uploading to S3")
            var uploadReq = URLRequest(url: URL(string: urlResponse.uploadUrl)!)
            uploadReq.httpMethod = "PUT"
            uploadReq.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")

            let (_, httpResponse) = try await URLSession.shared.upload(for: uploadReq, from: imageData)

            if let httpResp = httpResponse as? HTTPURLResponse,
               !(200...299).contains(httpResp.statusCode) {
                throw NSError(domain: "UploadError", code: httpResp.statusCode)
            }

            await MainActor.run {
                self.uploadProgress = 1.0
            }
            
            print("saving key to db")
            
            try await saveProfileImageKeyToDB(key: urlResponse.key)
            
            await MainActor.run {
                self.isUploading = false
            }

            return urlResponse.key
            

        } catch {
            await MainActor.run {
                self.uploadError = error.localizedDescription
                self.isUploading = false
            }
            throw error
        }
    }
    
    func uploadBio(bio: String) async throws {
        await MainActor.run {
            isUploading = true
            uploadProgress = 0.5
            uploadError = nil
        }
        
        do {
            let _ = try await APIClient.shared.post(endpoint: "/profile/bio", body: BioRequest(bio: bio), responseType: EmptyResponse.self)
            print("Bio saved: \(bio)")
            await MainActor.run {
                isUploading = false
                uploadProgress = 1.0
                uploadError = nil
            }
            
        } catch {
            await MainActor.run {
                self.uploadError = error.localizedDescription
                self.isUploading = false
            }
            throw error
            
        }
    }
    
    private func saveProfileImageKeyToDB(key: String) async throws {
        _ = try await APIClient.shared.post(
            endpoint: "/profile/avatar/save?key=\(key)",
            body: EmptyRequest(),
            responseType: EmptyResponse.self
        )
    }
}
