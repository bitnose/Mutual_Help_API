//
//  Demand.swift
//  App
//
//  Created by Sötnos on 03/07/2019.
//

import Vapor
import Foundation
import FluentPostgreSQL


// Demand Model

final class Demand : Codable {
    
    var id : UUID?
    var demand : String
    var demandCreatedAt : Date?
    var adID : Ad.ID
    
    init(demand : String, adID : Ad.ID) {
        self.demand = demand
        self.adID = adID
        
    }
    
    static var createdAtKey: TimestampKey? = \.demandCreatedAt
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
    
}
extension Demand : Migration {}

