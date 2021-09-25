//
//  ALOStatus.swift
//  ALOStatus
//
//  Created by Lawrence Bensaid on 11/09/2021.
//

import Foundation

struct ALOStatus: Decodable {
    
    static let preview = ALOStatus(message: "All clear", summary: "Preview", orchestrator: .preview)
    
    private enum CodingKeys: CodingKey {
        case message
        case summary
        case version
        case clients
        case service
        case endpoints
        case orchestrator
    }
    
    var message: String
    var summary: String
    var version: String
    var clients: [String: String]
    var service: [String: String]
    var endpoints: [String]
    var orchestrator: ALOOrchestrator
    
    private init(message: String, summary: String, version: String = "0.0.1", clients: [String: String] = [:], service: [String: String] = [:], endpoints: [String] = [], orchestrator: ALOOrchestrator) {
        self.message = message
        self.summary = summary
        self.version = version
        self.clients = clients
        self.service = service
        self.endpoints = endpoints
        self.orchestrator = orchestrator
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        message = try container.decode(String.self, forKey: .message)
        summary = try container.decode(String.self, forKey: .summary)
        version = try container.decode(String.self, forKey: .version)
        clients = try container.decode([String: String].self, forKey: .clients)
        service = try container.decode([String: String].self, forKey: .service)
        endpoints = try container.decode([String].self, forKey: .endpoints)
        orchestrator = try container.decode(ALOOrchestrator.self, forKey: .orchestrator)
    }
    
}
