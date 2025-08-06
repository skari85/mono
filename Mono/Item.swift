//
//  Item.swift
//  Mono
//
//  Created by Georg albert on 6.8.2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
