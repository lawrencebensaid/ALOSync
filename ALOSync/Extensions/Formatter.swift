//
//  Formatter.swift
//  Formatter
//
//  Created by Lawrence Bensaid on 18/09/2021.
//

import Foundation

extension Formatter {
    
    public static func relative(dateTimeStyle: RelativeDateTimeFormatter.DateTimeStyle = .named, unitsStyle: RelativeDateTimeFormatter.UnitsStyle = .full) -> RelativeDateTimeFormatter {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = dateTimeStyle
        formatter.unitsStyle = unitsStyle
        return formatter
    }
    
}
