//
//  DemandController.swift
//  App
//
//  Created by Sötnos on 03/07/2019.
//

import Foundation
import Vapor
import Fluent

struct DemandController : RouteCollection {
    
    // MARK: - Register Routes
    func boot(router: Router) throws {
        
        /*
         Create a new route path for the api/ads
         
         - Grouped Route (/api/ads) +  Request Type (POST, GET, PUT, DELETE) (+ Path component + Method)
         
         1. Post Request - Post route with method which creates a new Demand
         2. Get Request - Retrieve all demands
         3. Get Request - Get the Offers of the Demand
         4. Post Request - Add the Offer to Demand
         5. Delete Request - Delete Offer by ID
         */
        
        let demandRoutes = router.grouped("api/demands")
        let tokenAuthMiddleware = User.tokenAuthMiddleware() // 1
        let guardAuthMiddleware = User.guardAuthMiddleware() // 2
        let adminGroup = demandRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware, AdminMiddleware()) // 3
    
        
        adminGroup.post(use: createHandler) // 1
        adminGroup.get(use: getAllHandler) // 2
        demandRoutes.get(Demand.parameter, "offer",  use: getOffersOfDemandHandler) // 3
        adminGroup.post(Demand.parameter, "offer", Offer.parameter, use: addOffersHandler) // 4
        adminGroup.delete(Demand.parameter, use: deleteHandler) // 5
        
        
    }
    
    // MARK: - Handlers
    
    /*
     Create Demand
     1. Function return Future<Demand>
     2. Decode the request's JSON into an object. This is simple because the Model conforms to Content. Decode returns a Future; use flatMap(to:) to extract the object when decoding completes.
     3. Save the object.
     */
    
    func createHandler(_ req: Request) throws -> Future<Demand> { // 1
        return try req.content.decode(Demand.self).flatMap(to: Demand.self) { demand in
            print(demand.demand)
            return demand.save(on: req) // 3
        }// 2
        
    }
    
    /* Retrieve All Demands
     1. Only parameter is request itself
     2. Perform Query to Retrieve All (Fluent adds functions to models to be able to perform queries on them. Provides a thread to perform the work.) Function fetches all Objects from the table and returns an array of Objects
     */
    
    func getAllHandler(_ req: Request) throws -> Future<[Demand]> { // 1
        return Demand.query(on: req).all() // 2
    }
    
    
    
    
    
    /*
     Add Offers (sibling relationship)
     1. Define a new route handeler that returns Future<HTTPStatus>
     2. Use flatMap(to:_:_:) to extract both objects from the request's parameters to create a relationship between them
     3. Use attach(_:on:) to set up the relationship between objects. This creates a pivot model and saves it in the database. Transform the result into a 201 Created response.
     */
    
    func addOffersHandler(_ req: Request) throws -> Future<HTTPStatus> { // 1
        // 2
        return try flatMap(to: HTTPStatus.self, req.parameters.next(Demand.self), req.parameters.next(Offer.self)) { demand, offer in
            // 3
            return demand.trades.attach(offer, on: req).transform(to: .created)
            
        }
    }
    
    /*
     Get offers of the demand:
     1. Define route handler getOffersOfDemandHandler(_ :) returning Future<[Object]>.
     2. Extract the ad from the request's parameters and unwrap the returned future.
     3. Use the computed property to get the siblings of the selected object. Then use a Fluent query to return all the siblings.
     */
    
    func getOffersOfDemandHandler(_ req: Request) throws -> Future <[Offer]> { // 1
        
        return try req.parameters.next(Demand.self).flatMap(to: [Offer].self) { demand in // 2
            try demand.trades.query(on: req).all() // 3
        }
    }
    
    /*
     Delete by ID
     1. Method to DELETE to that returns Future<HTTPStatus>
     2. Extract the Object to delete from the request’s parameters.
     3. Delete the Object using delete(on:). Instead of requiring you to unwrap the returned Future, Fluent allows you to call delete(on:) directly on that Future. This helps tidy up code and reduce nesting. Fluent provides convenience functions for delete, update, create and save.
     4. Transform the result into a 204 No Content response. This tells the client the request has successfully completed but there’s no content to return.
     */
    
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> { // 1
        return try req.parameters.next(Demand.self) // 2
            .delete(on: req) // 3
            .transform(to: .noContent) // 4
    }
    
    
    
}
