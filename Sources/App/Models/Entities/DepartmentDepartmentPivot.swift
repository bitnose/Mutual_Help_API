//
//  DepartmentDepartmentPivot.swift
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
 3. Define two properties to link to the IDs of Departments. This is what holds the relationship.
 4. Define Left and Right types required by Pivot. This tells Fluent what the two models in the relationship are.
 5. Tell Fluent the key path of the two ID properties for each side of the relationship.
 6. Implement the throwing initializer, as required by ModifiablePivot.
 7. Confrom to ModifiablePivot. This allows you to use the syntactic sugar Vapor provides for adding and removing the relationships.
 
 
 */


// 1
final class DepartmentDepartmentPivot: PostgreSQLUUIDPivot {
    // 2
    var id: UUID?
    // 3
    var firstDepartmentID: Department.ID
    var secondDepartmentID: Department.ID
    
    // 4
    typealias Left = Department
    typealias Right = Department
    // 5
    static let leftIDKey: LeftIDKey = \.firstDepartmentID
    static let rightIDKey: RightIDKey = \.secondDepartmentID
    
    // 6
    init(_ firstDepartment: Department, _ secondDepartment: Department) throws {
        self.firstDepartmentID = try firstDepartment.requireID()
        self.secondDepartmentID = try secondDepartment.requireID()
    }
}

extension DepartmentDepartmentPivot: ModifiablePivot {} // 7

/*
 Foreign Key Constraints
 1. Conform the Pivot to Migration.
 2. Implement prepare(on:) as defined by Migration. This overrides the default implementation.
 3. Create the table for Pivot in the database.
 4. Use addProperties(to:) to add all the fields to the database.
 5. Add a reference between the objectID property on Pivot and the id property on Model. This sets up the foreign key constraint. .cascade sets a cascade schema reference action when you delete the Object. This means that the relationship is automatically removed instead of an error being thrown.
 
 
 */

extension DepartmentDepartmentPivot: Migration {// 1
    
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> { // 2
        return Database.create(self, on: connection) { builder in // 3
            try addProperties(to: builder) // 4
            builder.reference(from: \.firstDepartmentID, to: \Department.id, onDelete: .cascade) // 5
            builder.reference(from: \.secondDepartmentID, to: \Department.id, onDelete: .cascade) // 5
        }
    }
    
}
