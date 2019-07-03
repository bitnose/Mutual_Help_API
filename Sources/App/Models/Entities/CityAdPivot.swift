//
//  CityAdPivot.swift
//  App
//
//  Created by Sötnos on 03/07/2019.
//

import FluentPostgreSQL
import Foundation

/*
 
 Contains the Pivot model to manage the sibling relationship
 1. Define a new object that conforms to PostgreSQLUUIDPivot. This is a helper protocol on top of Fluent's Pivot protocol.
 2. Define an id for the model. Note this is a UUID type so you must import the Foundationn module in the file.
 3. Define two properties to link to the IDs of Objects. This is what holds the relationship.
 4. Define Left and Right types required by Pivot. This tells Fluent what the two models in the relationship are.
 5. Tell Fluent the key path of the two ID properties for each side of the relationship.
 6. Implement the throwing initializer, as required by ModifiablePivot.
 7. Conform to Migration so Fluent can set up the table.
 8. Confrom to ModifiablePivot. This allows you to use the syntactic sugar Vapor provides for adding and removing the relationships.
 
 
 */


// 1
final class CityAdPivot: PostgreSQLUUIDPivot {
    // 2
    var id: UUID?
    // 3
    var cityID: City.ID
    var adID: Ad.ID
    
    // 4
    typealias Left = City
    typealias Right = Ad
    // 5
    static let leftIDKey: LeftIDKey = \.cityID
    static let rightIDKey: RightIDKey = \.adID
    
    // 6
    init(_ cityID: City, _ adID: Ad) throws {
        self.cityID = try cityID.requireID()
        self.adID = try adID.requireID()
    }
}

extension CityAdPivot: ModifiablePivot {} // 9

/*
 Foreign Key Constraints
 1. Conform the Pivot to Migration.
 2. Implement prepare(on:) as defined by Migration. This overrides the default implementation.
 3. Create the table for CityAdPivot in the database.
 4. Use addProperties(to:) to add all the fields to the database.
 5. Add a reference between the adid property on CityAdPivot and the id property on Ad. This sets up the foreign key constraint. .cascade sets a cascade schema reference action when you delete the ad. This means that the relationship is automatically removed instead of an error being thrown.
 6. Add a reference between the cityID property on CityAdPivot and the id property on City. This sets up the foreign key constraint. Also set the schema reference action for deletion when deleting the city.
 
 */

extension CityAdPivot: Migration {// 1
    
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> { // 2
        return Database.create(self, on: connection) { builder in // 3
            try addProperties(to: builder) // 4
            builder.reference(from: \.adID, to: \Ad.id, onDelete: .cascade) // 5
            builder.reference(from: \.cityID, to: \City.id, onDelete: .cascade) // 6
        }
    }
    
}

