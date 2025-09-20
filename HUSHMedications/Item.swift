//
//  Item.swift
//  HUSHMedications
//
//  Created by Michael Lazar on 9/20/25.
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
