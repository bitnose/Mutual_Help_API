//
//  String+Extension.swift
//  App
//
//  Created by Sötnos on 28/07/2019.
//

import Foundation

/// An extension to base 64 encode and decode strings.
extension String {
    
/// Method to base 64 encode String
/// - Returns an optional string
/// - Uses .utf8 for encoding
    func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
    /// Method to base 64 decode String
    /// - Returns string which is a Base-64 encoded String
    func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }
}
