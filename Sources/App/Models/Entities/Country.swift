//
//  Country.swift
//  App
//
//  Created by Sötnos on 03/07/2019.
//

import Vapor
import Foundation
import FluentPostgreSQL


// Country Model

final class Country : Codable {
    
    var id : UUID?
    var country : String
    var createdAt : Date?
    
    init(country : String) {
        self.country = country
        
    }
    
    static var createdAtKey: TimestampKey? = \.createdAt
    
}



// Conform models
// Conform the Fluent's Model
extension Country: PostgreSQLUUIDModel {}
// Conform to Content, Migration and Parameter Models
extension Country : Migration {}
extension Country : Content {}
extension Country : Parameter {}

/*
 
 Extension to Get the Relationships (Children and Siblings)
 
 1. Add a computed property to Model to get an object's(department's) children(ads). This returns Fluent’s generic Children type.
 2. Use Fluent’s children(_:) function to retrieve the children. This takes the key path of the department reference on the ads.
 3. Add a computed property to Model to get an object's nearby areas.
 
 
 */

extension Country {
    
    /*
     1. Add a computed property to Model to get an object's(department's) children(ads). This returns Fluent’s generic Children type.
     2. Use Fluent’s children(_:) function to retrieve the children. This takes the key path of the department reference on the ads.
     */
    var departments : Children<Country, Department> { //1
        return children(\.countryID)// 2
        
    }
    
    
}



