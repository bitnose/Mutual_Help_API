//
//  Date+DateFormatter.swift
//  App
//
//  Created by Sötnos on 21/10/2019.
//

import Foundation

/// # Extension formats the Ad's date property to a date string in French

extension Date {
    
    /// # Function formats a date object to a date string in a French form and timezone.
    ///
    /// - Parameters:
    ///     - date : Date
    /// - Returns: String
    ///
    func formatToFrenchDate(date: Date) -> String {
        
        // DateFormatter converts between dates and their textual representations.
        let formatter = DateFormatter()
        // Set the values for properties
        formatter.timeZone = TimeZone.init(abbreviation: "CET") // Set the timezone be the Central Europian Time (France)
        formatter.locale = .init(identifier: "fr") // Use French locale
        formatter.timeStyle = .short // Time style : 00.00
        formatter.dateStyle = .medium // Date style : dd Oct YYYT
      
        // Convert a date to a string
        return formatter.string(from: date)
    }
}

