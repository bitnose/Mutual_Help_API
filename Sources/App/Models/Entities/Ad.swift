//
//  Ad.swift
//  App
//
//  Created by Sötnos on 03/07/2019.
//

import Foundation
import Vapor
import FluentPostgreSQL

/**
 # Class for the Ads : conforms Codable
 Properties:
 - ID : UUID ?
 - note : String - User's input about the note
 - cityID : City; Reference to the Department which owns the Ad (Parent-Child Relationship)
 - adCreatedAt : Date - Timestamp of the date when the model was created
 - updatedAt : Date - Timestamp of the date when the model was updated
 - generosity : Int - The Generosity of the ad; How generous is the ad from 0 - 100 ?
 - images : Array of Strings - Optional array of strings (the links to the image)
 - deletedAt: A property for Fluent to store the date you performed a soft delete on the model
 */

final class Ad : Codable {
    
    var id : UUID?
    var note : String
    var cityID : City.ID
    var adCreatedAt : Date?
    var updatedAt : Date?
    var images : [String]?
    var deletedAt: Date?
    var userID : User.ID

    // Initialize
    init(note : String, cityID : City.ID, images: [String]? = nil, userID : User.ID) {
        
        self.note = note
        self.cityID = cityID
        self.images = images
        self.userID = userID
    }
    
    // Fluent will automatically manage these records
    static var createdAtKey: TimestampKey? = \.adCreatedAt
    static var updatedAtKey : TimestampKey? = \.updatedAt
    // Add to new key path that Fluent checks when you call delete(on:). If the key path exists, Fluent sets the current date on the property and saves the updated model. Otherwise, it deletes the model from the database
    static var deletedAtKey : TimestampKey? = \.deletedAt
    
    /// # WillSoftDelete
    /// - parameters:
    ///     - req: Request
    ///     - ad : Ad to delete
    /// - throws: Abort error
    /// - returns: Future Void
    /// 1. This method soft deletes children of the ad what is going to be deleted. Call this method before deleting the ad. Function throws.
    /// 2. Query the demands of the ad and delete them. Catch errors and print a message and throw abort.
    /// 3. Query the offers of the ad and delete them. Catch errors and print a message and throw abort.
    /// 4. Return and Query the hearts of the ad and delete them, transform to void. Catch errors and print a message and throw abort.
    func willSoftDelete(on req: Request, ad: Ad) throws -> Future<Void> { // 1
    
        _ = try ad.demands.query(on: req).delete().catchMap({ error in
            print(error, "Can't delete the demands")
             throw Abort.init(.internalServerError)
        }) // 2
        _ = try ad.offers.query(on: req).delete().catchMap({ error in
             print(error, "Can't delete the offers.")
            throw Abort.init(.internalServerError)
        }) // 3
        
        // 4
        return try ad.hearts.query(on: req).delete().catchMap({ error in
             print(error, "Can't delete the hearts")
            
        }).transform(to: ())
    }
}

// MARK: - Extensions

// Conform the Fluent's Model
extension Ad: PostgreSQLUUIDModel {}
// Conform the Content and the Parameter
extension Ad : Content {}
extension Ad : Parameter {}


// MARK: - Relationships
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
    
    var city : Parent<Ad, City> { // 5
        return parent(\.cityID) // 6
    }
    
    var user : Parent<Ad, User> { // 5
        return parent(\.userID) // 6
    }
    
    
    // MARK: - Static functions
    
    /// # Helper Method to remove an image from the ad.
    ///
    /// - parameters:
    ///     - name : String
    ///     - to ad: Future Ad
    ///     - req: Request
    /// - throws: Abort
    /// - returns: Future Void
    ///
    /// 1. Parameters: a name of the image, a future ad model, request. Returns a Future<Void>
    /// 2. Return Future<Void> after executing a closure.
    /// 2.a) Unwrap the id of the ad.
    /// 2.b) Look if the user has the ad which is the same as the adID from the request. If it doesn't exists throw an abort (.forbidden).
    /// 3. Ensure that the images is not nul.
    /// 4. Get a index of the element and remove the element in that index.
    /// 5. Update the ad.images be equal to the updated array.
    /// 6. Return and save the ad and transform it to be void.
    static func removeImage(name : String, to ad: Future<Ad>, req: Request) throws -> Future<Void> { // 1
        
        let user = try req.requireAuthenticated(User.self)
        
        return ad.flatMap(to: Void.self) { ad in // 2
            
            let id = try ad.requireID() // 2a
            
            _ = try user.adsOfUser.query(on: req).filter(\Ad.id == id).first().unwrap(or: Abort(.forbidden)) // 2b
            
            guard var images = ad.images else {print("Ad doesn't have any images."); throw Abort(.notFound)} // 3
  
            _ = images.index(of: name).map {images.remove(at: $0)} // 4
            ad.images = images // 5
            return ad.save(on: req).transform(to: ()) // 6
        }
    }
    
    /// # Private Method to save image names to the ad.
    ///
    /// - parameters:
    ///     - name : String
    ///     - to id: UUID
    ///     - req: Request
    /// - throws: Abort
    /// - returns: Future Void
    ///
    /// 1. Helper method takes a string parameter(a name of the file), uuid(an id of the ad) and the request in as parameters. Returns Void.
    /// 2. Make a database query to the Ad table: Filter results with the ad id and get the first result. After completion handler flatMap the response to Future<Void>.
    /// 3. If foundAd equals exisitngAd ie. look if the ad with the required id was found. (unwrap foundAd)
    /// 4. If the ad doesn't have images.
    /// 5. Ad an array of string(name) to be images.
    /// 6. Save the updated ad and transform to the void.
    /// 7. If the ad has already images.
    /// 8. Append the new name to the images.
    /// 9. Save the updated ad and transform to the void.
    static func adImage(name: String, to id: UUID, req: Request) throws -> Future<Void> { // 1
        
        return Ad.query(on: req).filter(\Ad.id == id).first().flatMap(to: Void.self) { foundAd in // 2
            
            guard let existingAd = foundAd else {throw Abort(.internalServerError)} // 3
            
            if existingAd.images == nil { // 4
                existingAd.images = [name] // 5
                return existingAd.save(on: req).transform(to: ()) // 6
            } else { // 7
                existingAd.images!.append(name) // 8
                return existingAd.save(on: req).transform(to: ()) // 9
            }
        }
    }
    
    
}

// MARK: - Migrations

/*
 Setting up the Foreign Key Constraints
 1. Conform the Model to Migration
 2. Implement prepare(on:) as required by Migration. This overrides the default implementation.
 3. Create the table for Ad in the database
 4. Use addProperties(to:) to add all the fields to the database. This means you don't need to add each column manually.
 5. Add a reference between the cityID property on Ad and the id property on City. This sets up the foreign key constraint between the two tables
 */

extension Ad : Migration { // 1
    
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> { // 2
        return Database.create(self, on: connection) { builder in // 3
            try addProperties(to: builder) // 4
            builder.reference(from: \.cityID, to: \City.id) // 5
            builder.reference(from: \.userID, to: \User.id)
        }
    }
}


