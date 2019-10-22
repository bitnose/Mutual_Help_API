//
//  Demand.swift
//  App
//
//  Created by Sötnos on 03/07/2019.
//

import Vapor
import Foundation
import FluentPostgreSQL


/// Demand Model
/// - id : UUID
/// - demand : A Name of the Demand
/// - demandCreatedAt : A timestamp of the moment the demand was created.
/// - adID : A Parent Ad of the demand
///  - deletedAt: A property for Fluent to store the date you performed a soft delete on the model
final class Demand : Codable {
    
    var id : UUID?
    var demand : String
    var demandCreatedAt : Date?
    var adID : Ad.ID
    var deletedAt: Date?
    
    init(demand : String, adID : Ad.ID) {
        self.demand = demand
        self.adID = adID
        
    }
    
    static var createdAtKey: TimestampKey? = \.demandCreatedAt
    // Add to new key path that Fluent checks when you call delete(on:). If the key path exists, Fluent sets the current date on the property and saves the updated model. Otherwise, it deletes the model from the database
    static var deletedAtKey : TimestampKey? = \.deletedAt
}


// Conform models
// Conform the Fluent's Model
extension Demand: PostgreSQLUUIDModel {}
// Conform to Content and Parameter Models
extension Demand : Content {}
extension Demand : Parameter {}

/*
 
 Extension to Get the Relationships (Children and Siblings)
 
 1. Add a computed property to Model to get an object's(city) parent(Department). This returns Fluent’s generic Parent type.
 2. Use Fluent’s parent(_:) function to retrieve the parent.
 3. Add a computed property to Model to get an object's siblings.
 4. Return siblings.
 
 */

extension Demand {
    
    // Parent
    
    var ad : Parent<Demand, Ad> { // 1
        return parent(\.adID)// 2
    }
    
    /*
     Static function to create a demand
     1. Create a new demand with the provided demand and ad id.
     2. Save the new demand and transform the result to Void
     */
    static func addDemand(_ name: String, to ad: Ad, on req: Request) throws -> Future<Void> {
        let demand = Demand(demand: name, adID: try ad.requireID())
        return demand.save(on: req).transform(to: ())
        
    }
 
    
    
}


/*
 Setting up the Foreign Key Constraints
 1. Conform the Model to Migration
 2. Implement prepare(on:) as required by Migration. This overrides the default implementation.
 3. Create the table for Ad in the database
 4. Use addProperties(to:) to add all the fields to the database. This means you don't need to add each column manually.
 5. Add a reference between the adID property on Ad and the id property on Ad. This sets up the foreign key constraint between the two tables
 */

extension Demand : Migration { // 1
    
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> { // 2
        return Database.create(self, on: connection) { builder in // 3
            try addProperties(to: builder) // 4
            builder.reference(from: \.adID, to: \Ad.id) // 5
        }
    }
}


    
    


