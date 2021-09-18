//
//  ALOTask.swift
//  ALOTask
//
//  Created by Lawrence Bensaid on 11/09/2021.
//

import SwiftUI

struct ALOTask: Codable, Identifiable {
    
    static var preview: ALOTask { ALOTask(task: "task.\(Int.random(in: 10...99))", status: .running, startedAt: "\(Int.random(in: 1..<60)) seconds ago", progress: .random(in: 0...1), message: "Testing...") }
    
    private enum CodingKeys: CodingKey {
        case task
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

    var id: String { task }
    var task: String
    var status: Status
    var startedAt: String
    var progress: Float?
    var message: String?
    
    private init(task: String, status: Status = .unknown, startedAt: String, progress: Float? = nil, message: String) {
        self.task = task
        self.status = status
        self.startedAt = startedAt
        self.progress = progress
        self.message = message
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.task = try container.decode(String.self, forKey: .task)
        if let status = try? container.decodeIfPresent(String.self, forKey: .status) {
            self.status = Status(rawValue: status) ?? .unknown
        } else {
            self.status = .unknown
        }
        self.startedAt = try container.decode(String.self, forKey: .startedAt)
        if let progress = try? container.decodeIfPresent(String.self, forKey: .progress) {
            let str = String(progress.dropLast())
            self.progress = (str as NSString).floatValue / 100
        }
        self.message = try? container.decodeIfPresent(String.self, forKey: .message)
    }
    
}


struct ALOJob: Identifiable, Equatable {

    var id: String { name }
    var name: String
    var message: String?
    
}
