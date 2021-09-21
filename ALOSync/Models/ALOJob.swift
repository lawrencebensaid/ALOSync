//
//  ALOJob.swift
//  ALOJob
//
//  Created by Lawrence Bensaid on 21/09/2021.
//

import Foundation

struct ALOJob: Decodable, Identifiable {

    var id: String
    var lastRun: Date?
    var nextRun: Date?
    var message: String?
    
    private enum CodingKeys: CodingKey {
        case id
        case lastRunAt
        case nextRunAt
        case message
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        let lastRun = try? container.decodeIfPresent(Double.self, forKey: .lastRunAt)
        self.lastRun = lastRun != nil ? Date(timeIntervalSince1970: lastRun! / 1000) : nil
        let nextRun = try? container.decodeIfPresent(Double.self, forKey: .nextRunAt)
        self.nextRun = nextRun != nil ? Date(timeIntervalSince1970: nextRun! / 1000) : nil
        self.message = try? container.decodeIfPresent(String.self, forKey: .message)
    }
    
}
