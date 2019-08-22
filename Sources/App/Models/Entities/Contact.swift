//
//  Contact.swift
//  App
//
//  Created by Sötnos on 03/07/2019.
//

import Vapor
import Foundation
import FluentPostgreSQL


/// Contact Model
/// - id : UUID
/// - adLink : A Link to the ad in the facebook
/// - facebookLink : A Link to the messenger of the contact
/// - createdAt : A timestamp of the moment when the model was created.
/// - deletedAt: A property for Fluent to store the date you performed a soft delete on the model.

final class Contact : Codable {
    
    var id : UUID?
    var adLink : String
    var facebookLink : String
    var contactName : String
    var createdAt : Date?
    var deletedAt: Date?
    
    // Initialize
    init(adLink : String, facebookLink : String, contactName : String) {
        
        self.adLink = adLink
        self.facebookLink = facebookLink
        self.contactName = contactName
    }
    
    static var createdAtKey: TimestampKey? = \.createdAt // Creates a timestamp automatically when the model was created
    // Add to new key path that Fluent checks when you call delete(on:). If the key path exists, Fluent sets the current date on the property and saves the updated model. Otherwise, it deletes the model from the database
    static var deletedAtKey : TimestampKey? = \.deletedAt
}


// Conform models
// Conform the Fluent's Model
extension Contact: PostgreSQLUUIDModel {}
// Conform to Content, Migration and Parameter Models
extension Contact : Migration {}
extension Contact : Content {}
extension Contact : Parameter {}

/*
 
 Extension to Get the Relationships (Children and Siblings)
 
 1. Add a computed property to Model to get an object's(city) parent(Department). This returns Fluent’s generic Parent type.
 2. Use Fluent’s parent(_:) function to retrieve the parent.
 3. Add a computed property to Model to get an object's cities.
 4. Return siblings.
 
 */

extension Contact {
    
    // Children
    
    var ads : Children<Contact, Ad> { // 1
        return children(\.contactID)// 2
    }
    
    
    /*
     Static function to edit contact
     1. Create a new demand with the provided demand and ad id.
     2. Save the new demand and transform the result to Void
     */
    //    static func editContact(_ name: String, _ email: String, _ link: String, contact: Contact.ID, on req: Request) throws -> Future<Void> {
    //        let contact =
    //        return contact.save(on: req).transform(to: ())
    //
    //    }
    
}

