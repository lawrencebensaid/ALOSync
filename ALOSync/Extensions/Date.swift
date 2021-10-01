//
//  Date.swift
//  Date
//
//  Created by Lawrence Bensaid on 30/09/2021.
//

import Foundation

extension Date {
    
    @available(macOS, deprecated: 12)
    init(_ iso8601Value: String) throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        guard let date = formatter.date(from: iso8601Value) else { throw ParsingError() }
        self = date
    }
    
}
