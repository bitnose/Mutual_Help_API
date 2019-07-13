//
//  HeartController.swift
//  App
//
//  Created by Sötnos on 03/07/2019.
//

import Foundation
import Vapor
import Fluent

struct HeartController : RouteCollection {
    
    // MARK: - Register Routes
    func boot(router: Router) throws {
        
        /*
         Create a new route path for the api/ads
         
         - Grouped Route (/api/ads) +  Request Type (POST, GET, PUT, DELETE) (+ Path component + Method)
         
         1. Post Request - Post route with method which creates new offers
         2. Get Request - Retrieve all Offers
         3. Delete Requst - Delete Heart
         */
        
        let heartRoutes = router.grouped("api/hearts")
        heartRoutes.post(use: createHandler) // 1
        heartRoutes.delete(Heart.parameter, use: deleteHandler) //
        
    }
    
    // MARK: - Handlers
    
    /*
     Create Heart
     1. Function return Future<Heart>
     2. Decode the request's JSON into an object. This is simple because the Model conforms to Content. Decode returns a Future; use flatMap(to:) to extract the object when decoding completes.
     3. Save the object.
     */
    
    func createHandler(_ req: Request) throws -> Future<Heart> { // 1
        return try req.content.decode(Heart.self).flatMap(to: Heart.self) { heart in // 2
            return heart.save(on: req) // 3

        }
        
    }
    
    /*
     Delete by ID
     1. Method to DELETE to /api/hearts/<ID> that returns Future<HTTPStatus>
     2. Extract the Object to delete from the request’s parameters.
     3. Delete the Object using delete(on:). Instead of requiring you to unwrap the returned Future, Fluent allows you to call delete(on:) directly on that Future. This helps tidy up code and reduce nesting. Fluent provides convenience functions for delete, update, create and save.
     4. Transform the result into a 204 No Content response. This tells the client the request has successfully completed but there’s no content to return.
     */
    
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> { // 1
        return try req.parameters.next(Heart.self) // 2
            .delete(on: req) // 3
            .transform(to: .noContent) // 4
    }
    
    
}
