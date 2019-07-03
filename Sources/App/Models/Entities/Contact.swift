//
//  Contact.swift
//  App
//
//  Created by Sötnos on 03/07/2019.
//

import Vapor
import Foundation
import FluentPostgreSQL


// Contact Model

final class Contact : Codable {
    
    var id : UUID?
    var adLink : String
    var facebookLink : String
    var contactName : String
    var createdAt : Date?
    
    
    // Initialize
    init(adLink : String, facebookLink : String, contactName : String) {
        
        self.adLink = adLink
        self.facebookLink = facebookLink
        self.contactName = contactName
    }
    
    static var createdAtKey: TimestampKey? = \.createdAt // Creates a timestamp automatically when the model was created
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

