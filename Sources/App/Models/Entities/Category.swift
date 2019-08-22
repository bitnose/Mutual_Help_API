//
//  Category.swift
//  App
//
//  Created by Sötnos on 03/07/2019.
//

import Vapor
import Foundation
import FluentPostgreSQL


/// The Category
/// - deletedAt: A property for Fluent to store the date you performed a soft delete on the model

final class Category : Codable {
    
    var id : UUID?
    var name : String
    var mainCategoryID : Category.ID
    var deletedAt: Date?
    
    init(name : String, mainCategoryID : Category.ID) {
        self.name = name
        self.mainCategoryID = mainCategoryID
        
    }
    
    // Add to new key path that Fluent checks when you call delete(on:). If the key path exists, Fluent sets the current date on the property and saves the updated model. Otherwise, it deletes the model from the database
    static var deletedAtKey : TimestampKey? = \.deletedAt
}

// Conform models
// Conform the Fluent's Model
extension Category: PostgreSQLUUIDModel {}
// Conform to Content and Parameter Models
extension Category : Content {}
extension Category : Parameter {}

/*
 Create a very first (root)category when Application first boots up.
 1. Defien a new type that conforms to Migration.
 2. Defien which database type this migration is for.
 3. Implement the required prepare(on:).
 4. Generate an id what is the "parent"
 5. Create a new category with the name rootcategory with the parentID what we just generated.
 6. Save the user and transform the result to Void, the return type of prepare(on:).
 7. Implement the required revert(on:). .done(on:) returns a pre-completed Future<Void>.
 TODO: - Password update
 */


struct RootCategory: Migration { // 1
    
    typealias Database = PostgreSQLDatabase // 2
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> { // 3
        let id = UUID()// 4
        let rootCategory = Category(name: "RootCategory", mainCategoryID: id)// 5
        return rootCategory.save(on: connection).transform(to: ()) // 6
    }
    static func revert(on connection: PostgreSQLConnection) -> Future<Void> { // 7
        return .done(on: connection)
    }
}

/*
 1. Add a computed property to Model to get an object's(category) children(categories). This returns Fluent’s generic Children type.
 2. Use Fluent’s children(_:) function to retrieve the children. This takes the key path of the maincategory reference on the subcategories.
 3. Set Up the Parent-Child Relationship: Add computed property to Object to get the object of its owner. This returns Fluent's generic parent type.
 4. Use Fluent't parent(_:) function to retrieve the parent. This takes the key path of the parent reference on the child.
 5. Sibling relationship
 6. Use Fluent's sibling() function to retrieve sibling.
 */

extension Category {
    
    // Children
    
    var subCategories : Children<Category, Category> { //1
        return children(\.mainCategoryID)// 2
    }
    
    // Parent
    
    var mainCategory : Parent<Category, Category> { // 3
        return parent(\.mainCategoryID)// 4
    }
    
    // Siblings
    
    var offers : Siblings<Category, Offer, CategoryOfferPivot> { // 5
        return siblings() // 6
    }
    
    var demands : Siblings<Category, Demand, CategoryDemandPivot> { // 5
        return siblings() // 6
    }
    
}

/// MARK: - Migration

/*
 Setting up the Foreign Key Constraints
 1. Conform the Model to Migration
 2. Implement prepare(on:) as required by Migration. This overrides the default implementation.
 3. Create the table for Ad in the database
 4. Use addProperties(to:) to add all the fields to the database. This means you don't need to add each column manually.
 5. Add a reference between the objectID property on Object and the id property on Anctother Objex. This sets up the foreign key constraint between the two tables
 */

extension Category : Migration { // 1
    
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> { // 2
        return Database.create(self, on: connection) { builder in // 3
            try addProperties(to: builder) // 4
            builder.reference(from: \.mainCategoryID, to: \Category.id) // 5
            
            
            
        }
    }
    
}
