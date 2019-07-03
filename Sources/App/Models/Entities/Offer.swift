//
//  Offer.swift
//  App
//
//  Created by Sötnos on 03/07/2019.
//

//
//  Offer.swift
//  App
//
//  Created on 20/04/2019.
//

import Vapor
import Foundation
import FluentPostgreSQL


// Offer Model

final class Offer : Codable {
    
    var id : UUID?
    var offer : String
    var offerCreatedAt : Date?
    var adID : Ad.ID
    
    init(offer : String, adID : Ad.ID) {
        self.offer = offer
        self.adID = adID
        
    }
    
    static var createdAtKey: TimestampKey? = \.offerCreatedAt
}


// Conform models
// Conform the Fluent's Model
extension Offer: PostgreSQLUUIDModel {}
// Conform to Content and Parameter Models
extension Offer : Content {}
extension Offer : Parameter {}

/*
 
 Extension to Get the Relationships (Children and Siblings)
 
 1. Add a computed property to Model to get an object's parent. This returns Fluent’s generic Parent type.
 2. Use Fluent’s parent(_:) function to retrieve the parent.
 3. Add a computed property to Model.
 4. Return siblings.
 
 */

extension Offer {
    
    var ad : Parent<Offer, Ad> { // 1
        return parent(\.adID)// 2
    }
    
    var trades : Siblings<Offer, Demand, DemandOfferPivot> { // 3
        return siblings() // 4
    }
    
    var categories : Siblings<Offer, Category, CategoryOfferPivot> { // 3
        return siblings() // 4
    }
    
    
    /*
     Static function to create an offer
     1. Create a new offer with the provided offer and ad id.
     2. Save the new offer and transform the result to Void
     */
    static func addOffer(_ offer: String, to ad: Ad, on req: Request) throws -> Future<Void> {
        let offer = Offer(offer: offer, adID: try ad.requireID()) // 1
        return offer.save(on: req).transform(to: ()) // 2
    }
    
}

// Conform the Model to Migration
extension Offer : Migration {}


