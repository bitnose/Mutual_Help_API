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
    
    // Siblings
    
    var trades : Siblings<Demand, Offer, DemandOfferPivot> { // 3
        return siblings() // 4
    }
    
    var categories : Siblings<Demand, Category, CategoryDemandPivot> { // 3
        return siblings() // 4
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
    
    
    /// Update the existing demand or create new one.
    /// 1. Parameters are array of names of the demands (strings), the ad, and the request.
    /// 2. Make a database query to get the demands of the ad.
    /// 3. Delete children by looping the array trough.
    /// 4. If the name is an empty string continue to iterate the array.
    /// 5. If the name is not an empty string create new demand by calling another method.
    
    static func updateDemands(_ names: [String], to ad: Ad, on req: Request) throws { // 1
        
        print("moi")
        _ = try ad.demands.query(on: req).delete() // 2
        for name in names { // 3
            
            if name.isEmpty { // 4
                continue
            } else { // 5
                _ = try self.addDemand(name, to: ad, on: req)
            }
        }
    }
    
    
    
    
    
    
}
extension Demand : Migration {}

