import Foundation

enum APIError: Error {
    case invalidURL
    case networkError(Error)
    case unauthenticated
    case decodingError(Error)
    case serverError(String)
}

class APIClient {
    static let shared = APIClient()
    
    // Switch to your production domain or IP Address here
//    private let baseURL = "http://localhost:3000/api"
//    private let baseURL = "http://192.168.1.87:3000/api"
    private let baseURL = "https://www.payday2dle.com/api"

    
    private init() {}
    
    private func makeRequest(endpoint: String, method: String, body: Data? = nil) throws -> URLRequest {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add Authorization header asynchronously or using SessionManager
        // Because SessionManager is MainActor we access it synchronously if needed or just pass it in
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = body
        return request
    }
    
    func get<T: Decodable>(endpoint: String, responseType: T.Type) async throws -> T {
        let request = try makeRequest(endpoint: endpoint, method: "GET")
        return try await execute(request: request, responseType: responseType)
    }
    
    func post<T: Decodable, U: Encodable>(endpoint: String, body: U, responseType: T.Type) async throws -> T {
        let encoder = JSONEncoder()
        let data = try encoder.encode(body)
        let request = try makeRequest(endpoint: endpoint, method: "POST", body: data)
        return try await execute(request: request, responseType: responseType)
    }
    
    func delete<T: Decodable, U: Encodable>(endpoint: String, body: U, responseType: T.Type) async throws -> T {
        let encoder = JSONEncoder()
        let data = try encoder.encode(body)
        let request = try makeRequest(endpoint: endpoint, method: "DELETE", body: data)
        return try await execute(request: request, responseType: responseType)
    }
    
    private func execute<T: Decodable>(request: URLRequest, responseType: T.Type) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(NSError(domain: "InvalidResponse", code: 0, userInfo: nil))
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            if httpResponse.statusCode == 401 { throw APIError.unauthenticated }
            if let errorMsg = try? JSONDecoder().decode([String: String].self, from: data), let msg = errorMsg["error"] {
                throw APIError.serverError(msg)
            }
            throw APIError.serverError("Status code: \(httpResponse.statusCode)")
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch {
            print("DECODING ERROR: \(error)")
            throw APIError.decodingError(error)
        }
    }
    
// USELESS, BUT MAY BE USEFUL LATER?
    
//    func fetchVideosDetails(videos: [Video]) async -> [Post] {
//        await withTaskGroup(of: Post?.self) { group in
//            
//            for video in videos {
//                group.addTask {
//                    do {
//                        return try await APIClient.shared.get(
//                            endpoint: "/videos/\(video.video_id)",
//                            responseType: Post.self
//                        )
//                    } catch {
//                        // log error if needed
//                        print("Failed to fetch video \(video.video_id): \(error)")
//                        return nil
//                    }
//                }
//            }
//            
//            var results: [Post] = []
//            
//            for await post in group {
//                if let post = post {
//                    results.append(post)
//                }
//            }
//            
//            return results
//        }
//    }
}
