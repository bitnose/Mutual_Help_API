//
//  Heart.swift
//  App
//
//  Created by Sötnos on 03/07/2019.
//

//
//  Heart.swift
//  App
//
//  Created by Sötnos on 20/04/2019.
//

import Vapor
import Foundation
import FluentPostgreSQL


/// Heart Model
/// - id : UUID
/// - heartCreatedAt : A timestamp of the moment the model was created
/// - adID : The parent of the heart (This ad owns the heart)
/// - token : A token identifies the user which created the heart
/// - deletedAt: A property for Fluent to store the date you performed a soft delete on the model
final class Heart : Codable {
    
    var id : UUID?
    var heartCreatedAt : Date?
    var adID : Ad.ID
    var deletedAt: Date?
    var userID : User.ID
    
    
    init(adID: Ad.ID, userID: User.ID) {
        self.adID = adID
        self.userID = userID
    }
    
    static var createdAtKey: TimestampKey? = \.heartCreatedAt
    // Add to new key path that Fluent checks when you call delete(on:). If the key path exists, Fluent sets the current date on the property and saves the updated model. Otherwise, it deletes the model from the database
    static var deletedAtKey : TimestampKey? = \.deletedAt
}




// Conform models
// Conform the Fluent's Model
extension Heart: PostgreSQLUUIDModel {}
// Conform to Content and Parameter Models
extension Heart : Content {}
extension Heart : Parameter {}

/*
 
 Extension to Get the Relationships (Children and Siblings)
 
 1. Add a computed property to Model to get an object's parent. This returns Fluent’s generic Parent type.
 2. Use Fluent’s parent(_:) function to retrieve the parent.
 
 */

extension Heart {
    
    var ad : Parent<Heart, Ad> { // 1
        return parent(\.adID)// 2
        
    }
    
    var user : Parent<Heart, User>? { // 1
        return parent(\.userID)// 2
        
    }
    
}

// Conform the Model to Migration




/*
 Setting up the Foreign Key Constraints
 1. Conform the Model to Migration
 2. Implement prepare(on:) as required by Migration. This overrides the default implementation.
 3. Create the table for Ad in the database
 4. Use addProperties(to:) to add all the fields to the database. This means you don't need to add each column manually.
 5. Add a reference between the userID property on Heart and the id property on Ad. This sets up the foreign key constraint between the two tables
 */

extension Heart : Migration { // 1
    
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> { // 2
        return Database.create(self, on: connection) { builder in // 3
            try addProperties(to: builder) // 4
            builder.reference(from: \.userID, to: \User.id) // 5
        }
    }
}
