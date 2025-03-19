import Foundation
import ApphudSDK

// Serials List
struct Response: Decodable {
    let error: Bool
    let data: VideoData
}

struct VideoData: Decodable {
    let tags: [Tag]
    let categories: [Category]
    let videos: [Video]
}

struct Tag: Decodable {
    let id: Int
    let title: String
}

struct Category: Decodable {
    let id: Int
    let title: String
    let pos: Int
}

struct Video: Decodable {
    let id: Int
    let pos: Int?
    let title: String
    let description: String
    let cover: String
    let categoryId: Int
    let tagId: Int
    let totalEpisodes: Int
    let isAutoUnlock: Bool
    var isFavourite: Bool
    var isSelected: Bool?
}

// Series

struct EpisodeResponse: Decodable {
    let error: Bool
    let data: EpisodeData
}

struct EpisodeData: Decodable {
    let episodes: [Episode]
}

struct Episode: Decodable {
    let id: Int
    let videoId: Int
    let episode: Int
    let price: Int
    let isFree: Bool
    let isAvailable: Bool
    let totalLikes: Int
    let isLiked: Bool?
    let videoUrl: String?
}

// isFavourite

struct FavouriteResponse: Decodable {
    let error: Bool
    let data: FavouriteData
}

struct FavouriteData: Decodable {
    let video: Video
}

// Specific Video

struct SpecificVideoResponse: Decodable {
    let error: Bool
    let data: SpecificVideoData
}

struct SpecificVideoData: Decodable {
    let video: Video
}

final class NetworkService {
    static let shared = NetworkService()
    private let baseURL = "https://shortsdrama.online/api/video/fetch"
    private let uuid = "281f8c9a-213d-4eda-b3a1-d7630546478b"

    private init() {}
    
    func fetchVideos() async throws -> VideoData {
        guard var components = URLComponents(string: baseURL) else { throw URLError(.badURL) }

        components.queryItems = [
            URLQueryItem(name: "uuid", value: uuid),
            URLQueryItem(name: "lang", value: "ru")
        ]

        guard let url = components.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer e8b2dac6-7413-471c-a9fc-78e2bc697990", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300
        let session = URLSession(configuration: config)

        return try await withCheckedThrowingContinuation { continuation in
            let task = session.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }
                
                guard let data = data else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }

                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(Response.self, from: data)
                    continuation.resume(returning: response.data)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            task.resume()
        }
    }
    
    func fetchVideoEpisodes(videoId: Int) async throws -> [Episode] {
        var components = URLComponents(string: "https://shortsdrama.online/api/video/episodes")!
        components.queryItems = await [
            URLQueryItem(name: "uuid", value: Apphud.userID()),
            URLQueryItem(name: "videoId", value: "\(videoId)"),
            URLQueryItem(name: "lang", value: "ru")
        ]
        
        guard let url = components.url else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer e8b2dac6-7413-471c-a9fc-78e2bc697990", forHTTPHeaderField: "Authorization")

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300
        let session = URLSession(configuration: config)
        
        return try await withCheckedThrowingContinuation { continuation in
            let task = session.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }
                
                guard let data = data else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(EpisodeResponse.self, from: data)
                    continuation.resume(returning: response.data.episodes)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            task.resume()
        }
    }
    
    func decryptData(data: String, secretKey: String) -> String {
        if let dataDecoded = Data(base64Encoded: data),
           let keyData = secretKey.data(using: .utf8) {
            let key = keyData.map { $0 }
            let decrypted = dataDecoded.enumerated().map { index, byte in
                byte ^ key[index % key.count]
            }
            return String(bytes: decrypted, encoding: .utf8) ?? ""
        }
        return ""
    }
    
    func addToFavourites(videoId: Int) async throws {
        let url = URL(string: "https://shortsdrama.online/api/video/favourite")!
        
        let requestBody: [String: Any] = [
            "uuid": uuid,
            "videoId": videoId
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer e8b2dac6-7413-471c-a9fc-78e2bc697990", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300
        let session = URLSession(configuration: config)

        return try await withCheckedThrowingContinuation { continuation in
            let task = session.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }
                
                guard let data = data else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(FavouriteResponse.self, from: data)
                    continuation.resume(returning: ())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            task.resume()
        }
    }
    
    func fetchSpecificVideo(videoId: Int) async throws -> Video {
        guard var components = URLComponents(string: "https://shortsdrama.online/api/video/fetchSpecific") else {
            throw URLError(.badURL)
        }

        components.queryItems = [
            URLQueryItem(name: "uuid", value: uuid),
            URLQueryItem(name: "lang", value: "ru"),
            URLQueryItem(name: "id", value: "\(videoId)")
        ]

        guard let url = components.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer e8b2dac6-7413-471c-a9fc-78e2bc697990", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300
        let session = URLSession(configuration: config)

        return try await withCheckedThrowingContinuation { continuation in
            let task = session.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }

                guard (200...299).contains(httpResponse.statusCode) else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }

                guard let data = data else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }

                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(FavouriteResponse.self, from: data)
                    continuation.resume(returning: response.data.video)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            task.resume()
        }
    }
}
