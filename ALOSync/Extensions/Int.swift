//
//  Int.swift
//  Int
//
//  Created by Lawrence Bensaid on 13/09/2021.
//

import Foundation

extension Int {
    
    func bytesString(format: ByteCountFormatter.Units = [.useAll]) -> String {
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = format
        bcf.countStyle = .file
        return bcf.string(fromByteCount: Int64(self))
    }
    
}
