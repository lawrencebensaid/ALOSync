//
//  ALOOrchestrator.swift
//  ALOOrchestrator
//
//  Created by Lawrence Bensaid on 11/09/2021.
//

import SwiftUI

class ALOOrchestrator: ObservableObject, Decodable {
    
    static let preview = ALOOrchestrator(message: "Orchestrating", tasks: [.preview, .preview])
    
    private enum CodingKeys: CodingKey {
        case status
        case message
        case jobs
        case tasks
    }
    
    enum Status: String, Codable {
        case idle = "idle"
        case cleaningUp = "cleaning up"
        case busy = "busy"
        case unknown = "unknown"
        
        var color: Color? {
            switch self {
            case .idle: return Color(.systemGreen)
            case .cleaningUp: return Color(.systemTeal)
            case .busy: return Color(.systemOrange)
            default: return nil
            }
        }
    }
    
    var status: Status
    var message: String?
    var jobs: [ALOJob]
    var tasks: [ALOTask]
    
    private init(status: Status = .unknown, message: String?, jobs: [ALOJob] = [], tasks: [ALOTask] = []) {
        self.status = status
        self.message = message
        self.jobs = jobs
        self.tasks = tasks
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let status = try? container.decodeIfPresent(String.self, forKey: .status) {
            self.status = Status(rawValue: status) ?? .unknown
        } else {
            self.status = .unknown
        }
        self.message = try container.decodeIfPresent(String.self, forKey: .message)
        self.jobs = try container.decode([ALOJob].self, forKey: .jobs)
        self.tasks = try container.decode([ALOTask].self, forKey: .tasks)
    }
    
}

