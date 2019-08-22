//
//  Offer.swift
//  App
//
//  Created by Sötnos on 03/07/2019.
//
import Vapor
import Foundation
import FluentPostgreSQL


/// Offer Model
/// - id : UUID
/// - offer : A name of the offer
/// - offerCreatedAt : A timestamp of the moment when the model was created.
/// - adID : The parent of the offer.
/// - deletedAt: A property for Fluent to store the date you performed a soft delete on the model
final class Offer : Codable {
    
    var id : UUID?
    var offer : String
    var offerCreatedAt : Date?
    var adID : Ad.ID
    var deletedAt: Date?
    // Init
    init(offer : String, adID : Ad.ID) {
        self.offer = offer
        self.adID = adID
        
    }
    
    static var createdAtKey: TimestampKey? = \.offerCreatedAt
    // Add to new key path that Fluent checks when you call delete(on:). If the key path exists, Fluent sets the current date on the property and saves the updated model. Otherwise, it deletes the model from the database
    static var deletedAtKey : TimestampKey? = \.deletedAt
}


// MARK: - Conform models
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
    
    /// Static function to create an offer
    /// 1. Create a new offer with the provided offer and ad id.
    /// 2. Save the new offer and transform the result to Void.
    static func addOffer(_ offer: String, to ad: Ad, on req: Request) throws -> Future<Void> {
        let offer = Offer(offer: offer, adID: try ad.requireID()) // 1
        return offer.save(on: req).transform(to: ()) // 2
    }
    
    /// Update the existing offer or create new one.
    /// 1. Parameters are array of names of the offers (strings), the ad, and the request.
    /// 2. Make a database query to get the offers of the ad.
    /// 3. Delete children by looping the array trough.
    /// 4. If the name is empty string, continue iterating the array.
    /// 5. Else create a new offer by calling another static method.
    static func updateOffers(_ names: [String], to ad: Ad, on req: Request) throws { // 1
        
        _ = try ad.offers.query(on: req).delete() // 2
        for name in names { // 3
            
            
            if name.isEmpty { // 4
                continue
            } else { // 5
                 _ = try self.addOffer(name, to: ad, on: req) //
            }
        }
    }
}

// Conform the Model to Migration
extension Offer : Migration {}


