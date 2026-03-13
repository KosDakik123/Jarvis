//
//  Item.swift
//  Jarvis
//
//  Created by 42 on 06.03.26.
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
