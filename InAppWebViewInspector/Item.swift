//
//  Item.swift
//  InAppWebViewInspector
//
//  Created by Evan Anger on 8/19/25.
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
