//
//  ALOTask.swift
//  ALOTask
//
//  Created by Lawrence Bensaid on 11/09/2021.
//

import SwiftUI

struct ALOTask: Codable, Identifiable {
    
    static var preview: ALOTask { ALOTask(id: "task.\(Int.random(in: 10...99))", status: .running, startedAt: Date(), progress: .random(in: 0...1), message: "Testing...") }
    
    private enum CodingKeys: CodingKey {
        case id
        case status
        case startedAt
        case progress
        case message
    }
    
    public enum Status: String, Codable {
        case created = "created"
        case pending = "pending"
        case running = "running"
        case finished = "finished"
        case error = "error"
        case unknown = "unknown"
        
        var color: Color? {
            switch self {
            case .created: return Color(.systemTeal)
            case .pending: return Color(.systemTeal)
            case .running: return Color(.systemOrange)
            case .finished: return Color(.systemGreen)
            case .error: return Color(.systemRed)
            default: return nil
            }
        }
    }

    var id: String
    var status: Status
    var startedAt: Date?
    var progress: Float?
    var message: String?
    
    private init(id: String, status: Status = .unknown, startedAt: Date, progress: Float? = nil, message: String) {
        self.id = id
        self.status = status
        self.startedAt = startedAt
        self.progress = progress
        self.message = message
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        if let status = try? container.decodeIfPresent(String.self, forKey: .status) {
            self.status = Status(rawValue: status) ?? .unknown
        } else {
            self.status = .unknown
        }
        let startedAt = try? container.decodeIfPresent(Double.self, forKey: .startedAt)
        self.startedAt = startedAt != nil ? Date(timeIntervalSince1970: startedAt! / 1000) : nil
        self.progress = try? container.decodeIfPresent(Float.self, forKey: .progress)
        self.message = try? container.decodeIfPresent(String.self, forKey: .message)
    }
    
}


struct ALOJob: Codable, Identifiable {

    var id: String
    var ranAt: Date?
    var message: String?
    
    private enum CodingKeys: CodingKey {
        case id
        case ranAt
        case message
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        let ranAt = try? container.decodeIfPresent(Double.self, forKey: .ranAt)
        self.ranAt = ranAt != nil ? Date(timeIntervalSince1970: ranAt! / 1000) : nil
        self.message = try? container.decodeIfPresent(String.self, forKey: .message)
    }
    
}
