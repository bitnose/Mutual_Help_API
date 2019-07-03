//
//  City.swift
//  App
//
//  Created by Sötnos on 03/07/2019.
//

import Vapor
import Foundation
import FluentPostgreSQL


// City Model

final class City : Codable {
    
    var id : UUID?
    var city : String
    var departmentID : Department.ID
    
    init(city : String, departmentID : Department.ID) {
        self.city = city
        self.departmentID = departmentID
        
    }
}


// Conform models
// Conform the Fluent's Model
extension City: PostgreSQLUUIDModel {}
// Conform to Content and Parameter Models
extension City : Content {}
extension City : Parameter {}

/*
 
 Extension to Get the Relationships (Children and Siblings)
 
 1. Add a computed property to Model to get an object's(city) parent(Department). This returns Fluent’s generic Parent type.
 2. Use Fluent’s parent(_:) function to retrieve the parent.
 3. Add a computed property to Model to get an object's cities.
 4. Return siblings.
 
 */

extension City {
    
    // Parent
    
    var department : Parent<City, Department> { // 1
        return parent(\.departmentID)// 2
    }
    
    // Children
    var adsOfCity : Children<City, Ad> { // 1
        return children(\.cityID) // 2
    }
    
    /*
     1. Perform a query to search for a city with the provided name.
     2. If the city exists, set up the relationship and transform the result to Void. ( () is shorthand for Void().)
     3. If the city doesn't exist, create a new City object with the provided name and department.
     4. Save up the relationship and transform the result to Void.
     
     */
    //    static func addOffer(_ offer: String, to ad: Ad, on req: Request) throws -> Future<V> {
    //        let offer = Offer(offer: offer, adID: try ad.requireID()) // 1
    //        return offer.save(on: req).transform(to: ()) // 2
    
    static func createCity(_ city: String, to department: Department, on req: Request) throws -> Future<City> {
        
        return City.query(on: req).filter(\.city == city).first().flatMap(to: City.self) { existingCity in
            
            if let oldCity = existingCity {
                oldCity.departmentID = try department.requireID()
                return oldCity.save(on: req)
                
            } else {
                let newCity = City(city: city, departmentID: try department.requireID())
                return newCity.save(on: req)
            }
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
 5. Add a reference between the objectID property on Object and the id property on Object. This sets up the foreign key constraint between the two tables
 
 */

extension City : Migration { // 1
    
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> { // 2
        return Database.create(self, on: connection) { builder in // 3
            try addProperties(to: builder) // 4
            builder.reference(from: \.departmentID, to: \Department.id) // 5
        }
    }
}

