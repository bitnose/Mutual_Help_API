//
//  Ad.swift
//  App
//
//  Created by Sötnos on 03/07/2019.
//

import Foundation
import Vapor
import FluentPostgreSQL

/*
 
 Class for the Ads conform the Codable
 Properties:
 - ID : UUID ?
 - note : String - User's input about the note
 - cityID : City; Reference to the Department which owns the Ad (Parent-Child Relationship)
 - adCreatedAt : Date - Timestamp of the date when the model was created
 - updatedAt : Date - Timestamp of the date when the model was updated
 - generosity : Int - The Generosity of the ad; How generous is the ad from 0 - 100 ?
 - images : Array of Strings - Optional array of strings (the links to the image)
 - show : Bool - Boolean value if the model should be shown to the user's or not
 
 
 */

final class Ad : Codable {
    
    var id : UUID?
    var note : String
    var cityID : City.ID
    var adCreatedAt : Date?
    var updatedAt : Date?
    var contactID : Contact.ID
    var generosity : Int
    var images : [String]?
    var show : Bool = true
    // Initialize
    init(note : String, cityID : City.ID, contactID : Contact.ID, generosity: Int, images: [String]? = nil, show: Bool = true) {
        
        self.note = note
        self.cityID = cityID
        self.contactID = contactID
        self.generosity = generosity
        self.images = images
        self.show = show
    }
    
    // Fluent will automatically manage these records
    static var createdAtKey: TimestampKey? = \.adCreatedAt
    static var updatedAtKey : TimestampKey? = \.updatedAt
    
    


    
   
    
    
    
}

/// MARK: - Extensions

// Conform the Fluent's Model
extension Ad: PostgreSQLUUIDModel {}
// Conform the Content and the Parameter
extension Ad : Content {}
extension Ad : Parameter {}


/// MARK: - Relationships
/*
 Set Up the Parent-Child Relationship
 1. Add computed property to Ad to get the city object of the ad's owner. This returns Fluent's generic parent type.
 2. User Fluent't parent(_:) function to retrieve the parent. This takes the key path of the city reference on the ad.
 3. Get the Object's sibling
 4. Use Fluent's sibling() function to retrieve sibling.
 5. Add a computed property to Model to get an object's parent. This returns Fluent’s generic Parent type.
 6. Use Fluent’s parent(_:) function to retrieve the parent.
 */

extension Ad {
    
    // Children
    
    var demands : Children<Ad, Demand> { // 1
        return children(\.adID) // 2
    }
    
    var offers : Children<Ad, Offer> { // 1
        return children(\.adID) // 2
    }
    
    var hearts : Children<Ad, Heart> { // 1
        return children(\.adID) // 2
    }
    
    // Parent
    
    var contact : Parent<Ad, Contact> {// 5
        return parent(\.contactID) // 6
    }
    
    var city : Parent<Ad, City> { // 5
        return parent(\.cityID) // 6
    }
    
    
    
    
}

/// MARK: - Migration

/*
 Setting up the Foreign Key Constraints
 1. Conform the Model to Migration
 2. Implement prepare(on:) as required by Migration. This overrides the default implementation.
 3. Create the table for Ad in the database
 4. Use addProperties(to:) to add all the fields to the database. This means you don't need to add each column manually.
 5. Add a reference between the cityID property on Ad and the id property on City. This sets up the foreign key constraint between the two tables
 6. Add a reference between the contactID property on Ad and the id property on Contact. This sets up the foreign key constraint between the two tables
 */

extension Ad : Migration { // 1
    
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> { // 2
        return Database.create(self, on: connection) { builder in // 3
            try addProperties(to: builder) // 4
            builder.reference(from: \.cityID, to: \City.id) // 5
            builder.reference(from: \.contactID, to: \Contact.id)
            
            
        }
    }
}


