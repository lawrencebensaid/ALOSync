//
//  Release.swift
//  Release
//
//  Created by Lawrence Bensaid on 30/09/2021.
//

import Foundation

struct Release: Decodable, Identifiable {
    
    enum CodingKeys: CodingKey {
        case id
        case tag_name
        case name
        case prerelease
        case published_at
        case body
    }
    
    let id: Int
    let tag: String
    let name: String
    let body: String
    let isPrerelease: Bool
    let publishedAt: Date?
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.tag = try container.decode(String.self, forKey: .tag_name)
        self.name = try container.decode(String.self, forKey: .name)
        self.body = try container.decode(String.self, forKey: .body)
        self.isPrerelease = try container.decode(Bool.self, forKey: .prerelease)
        let publishedAt = try container.decode(String.self, forKey: .published_at)
        if #available(macOS 12, *) {
            self.publishedAt = try Date(publishedAt, strategy: .iso8601)
        } else {
            self.publishedAt = try Date(publishedAt)
        }
    }
    
    public static func fetch(_ complete: ((Result<[Release], APIError>) -> ())? = nil) {
        let request = URLRequest(url: URL(string: "https://api.github.com/repos/lawrencebensaid/ALOSync/releases")!)
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    complete?(.failure(APIError("Something went wrong")))
                    print(error.localizedDescription)
                    return
                }
                guard let data = data else { return }
                guard let status = (response as? HTTPURLResponse)?.statusCode else { return }
                if status != 200 {
                    print(status)
                    let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    complete?(.failure(APIError(json?["message"] as? String ?? "Something went wrong")))
                    return
                }
                if var releases = try? JSONDecoder().decode([Release].self, from: data) {
                    releases.sort { $0.publishedAt ?? Date() < $1.publishedAt ?? Date() }
                    complete?(.success(releases))
                    return
                }
                complete?(.failure(APIError("Something went wrong")))
            }
        }.resume()
    }
    
}
