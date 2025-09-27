//
//  Double+Formatting.swift
//  HUSHMedications
//
//  Created by AI Assistant on 9/23/25.
//

import Foundation

extension Double {
    /// Returns the double as a string with one decimal place (e.g., 3.1)
    var singleDecimalStr: String {
        String(format: "%.1f", self)
    }
}
