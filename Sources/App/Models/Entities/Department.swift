//
//  Department.swift
//  App
//
//  Created by Sötnos on 03/07/2019.
//


import Vapor
import Foundation
import FluentPostgreSQL

 /// Class for Departments
 /// - id : UUID
 /// - departmentNumber : A number of the department
 /// - departmentName : A name of the department
 /// - countryID : A country where the department locates (a parent)
 /// - deletedAt: A property for Fluent to store the date you performed a soft delete on the model

final class Department : Codable {
    
    var id : UUID?
    var departmentNumber : Int
    var departmentName : String
    var countryID : Country.ID
    var deletedAt: Date?
    
    
    
    init(departmentNumber : Int, departmentName : String, countryID : Country.ID) {
        self.departmentNumber = departmentNumber
        self.departmentName = departmentName
        self.countryID = countryID
        
    }
    // Add to new key path that Fluent checks when you call delete(on:). If the key path exists, Fluent sets the current date on the property and saves the updated model. Otherwise, it deletes the model from the database
    static var deletedAtKey : TimestampKey? = \.deletedAt
}

// Conform models
// Conform the Fluent's Model
extension Department: PostgreSQLUUIDModel {}
// Conform to Content and Parameter Models
extension Department : Content {}
extension Department : Parameter {}

/*
 
 Extension to Get the Relationships (Children and Siblings)
 
 1. Add a computed property to Model to get an object's children. This returns Fluent’s generic Children type.
 2. Use Fluent’s children(_:) function to retrieve the children.
 3. Add a computed property to Model to get an object's nearby areas.
 4. In a same model sibling relation, Fluent cannot infer which sibling you are referring to – the sides need to be specified. Use Fluent’s siblings(_:) function to retrieve the siblings
 5. Add computed property to Object to get the parent object. This returns Fluent's generic parent type.
 6. User Fluent't parent(_:) function to retrieve the parent.
 
 */

extension Department {
    
    // Children
    
    var cities : Children<Department, City> { //1
        return children(\.departmentID) // 2
    }
    
    // Siblings :
    // Computed property to Get the Department in the Perimeter of selected the model. --> USE THIS WHEN YOU WANT TO GET/SET DEPARTMENTS OF THE AREA OF THE SELECTED DEPARTMENT
    var departmentsInsideOfPerimeter : Siblings<Department, Department, DepartmentDepartmentPivot> { // 3
        return siblings(DepartmentDepartmentPivot.leftIDKey, DepartmentDepartmentPivot.rightIDKey) // 4
    }
    // Computed property to Get All the Centre Departments of the Perimeters where the selected Model is in.
    var departmentInsideOfPerimeters : Siblings<Department, Department, DepartmentDepartmentPivot> { // 3
        return siblings(DepartmentDepartmentPivot.rightIDKey, DepartmentDepartmentPivot.leftIDKey) // 4
    }
    
    // Parents
    
    var country : Parent<Department, Country> { // 5
        return parent(\.countryID)// 6
    }
    
    
    /*
     Static function to create a sibling relationship between the existing departments
     1. Perform a query to search for a department with the provided name.
     2. If the department exists i.e. if the error is not thrown, set up the relationship by creating a pivot (have to create manually because the relationship is between the same model) and transform the result to Void.
     */
    
    static func addDepartment(name: String, to department: Department, on req: Request) throws -> Future<Void> { // 1
        return Department.query(on: req).filter(\.departmentName == name).first().flatMap(to: Void.self) { foundDepartment in
            
            // 2
            guard let existingDepartment = foundDepartment else {throw Abort(.internalServerError)}
            let pivot = try DepartmentDepartmentPivot(department, existingDepartment) // 3
            
            return pivot.save(on: req).transform(to: ()) // 4
        }
    }
    
    /// Static function to create a pivot model between two department models. Method takes an id of department model, a department model and a request as parameters. Returns void.
    /// 1. Make a query to the Department table in the database, filter the result with the id and get the first result. FlatMap the Future<Department> to a Future<Void>.
    /// 2. Ensure that the existingDepartment was found ie. is not a nul.
    /// 3. Create a pivot model between the two department models. Same-Model consequence is that you will not be able to use the attach convenience method to add to the pivot table so you need to manually create one.
    /// 4. Save the pivot model and transform the future to void.
    static func addPivot(neighbourID: UUID, to department: Department, on req: Request) throws -> Future<Void> {
        
        return Department.query(on: req).filter(\Department.id == neighbourID).first().flatMap(to: Void.self) { existingDepartment in // 1
            guard let foundDepartment = existingDepartment else {throw Abort(.notFound)} // 2
            
            
            let pivot = try DepartmentDepartmentPivot(department, foundDepartment) // 3
            return pivot.save(on: req).transform(to: ()) // 4
        }
        
       
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

extension Department : Migration { // 1
    
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> { // 2
        return Database.create(self, on: connection) { builder in // 3
            try addProperties(to: builder) // 4
            builder.reference(from: \.countryID, to: \Country.id) // 5
        }
    }
}


