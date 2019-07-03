//
//  Heart.swift
//  App
//
//  Created by Sötnos on 03/07/2019.
//

//
//  Heart.swift
//  App
//
//  Created by Sötnos on 20/04/2019.
//

import Vapor
import Foundation
import FluentPostgreSQL


// Heart Model

final class Heart : Codable {
    
    var id : UUID?
    var heartCreatedAt : Date?
    var adID : Ad.ID
    var token : String
    
    init(token: String, adID : Ad.ID) {
        self.token = token
        self.adID = adID
    }
    
    static var createdAtKey: TimestampKey? = \.heartCreatedAt
}


// Conform models
// Conform the Fluent's Model
extension Heart: PostgreSQLUUIDModel {}
// Conform to Content and Parameter Models
extension Heart : Content {}
extension Heart : Parameter {}

/*
 
 Extension to Get the Relationships (Children and Siblings)
 
 1. Add a computed property to Model to get an object's parent. This returns Fluent’s generic Parent type.
 2. Use Fluent’s parent(_:) function to retrieve the parent.
 
 */

extension Heart {
    
    var ad : Parent<Heart, Ad> { // 1
        return parent(\.adID)// 2
        
    }
    
    /*
     Static function to create a heart
     1. Create a new heart with the provided token and ad id.
     2. Save the new demand and transform the result to Void
     */
    static func addHeart(_ token: String, to ad: Ad, on req: Request) throws -> Future<Void> {
        let heart = Heart(token: token, adID: try ad.requireID()) // 1
        return heart.save(on: req).transform(to: ()) // 2
        
    }
    
}

// Conform the Model to Migration


extension Heart : Migration {}

