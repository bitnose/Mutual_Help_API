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
        
        // Route groups
        // 1. Create a TokenAuthenticationMiddleware for User. This uses BearerAuthenticationMiddleware to extract the bearer token out of the request. The middleware then converts this token into a logged in user.
        // 2. Functionality: Error to throw if the type is not authed.
        // 3. This group of routes requires the user to have an admin access.
        // 4. This group of routes requires the user to have an admin access OR standard access.
        // 5. This group of routes requires that the user has an admin access OR standard access AND it ensures that the auhtenticated user is the one who created the ad what he/she is going to manipulate ie. it authorizes the user to perform the action. 
        
        let demandRoutes = router.grouped("demands")
        let tokenAuthMiddleware = User.tokenAuthMiddleware() // 1
        let guardAuthMiddleware = User.guardAuthMiddleware() // 2
//        let adminRoutes = demandRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware, AdminMiddleware()) // 3
        let standardRoutes = demandRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware) // 4
       
        
     
        // Grouped Routes (/api/ads) +  Request Type (POST, GET, PUT, DELETE) (+ Path component + Method)

        // MARK: - STANDARD ACCESS
        //
        // 1. Post Request - Post route with method which creates a new Demand
        
        standardRoutes.post("create", use: createHandler) // 1
        
        
    }
    
    // MARK: - Handlers
    
    /// # Create Demand
    ///
    /// - parameters :
    ///     - req: Request
    /// - throws: Abort
    /// - returns: Future[Demand]
    ///
    /// 1. Function returns Future<[Demand]>
    /// 2. Get the authenticated user.
    /// 3. Use flatMap(to:) to extract the objects when decoding completes. Decode the request's JSON into an object. This is simple because the Model conforms to Content. Decode returns a Future.
    /// 4. Make a query to the ad table in the database, filter results with the data's adID and return Future<[Demand]>.
    /// 5. Unwrap the result of the query.
    /// 6. Look if the id of the user matches with the creator of the ad.
    /// 7. If yes: Make an array by mapping the given closure over the sequence’s elements. This closure creates an ad model and saves it on the database.
    /// 8. Return Future<[Demand]> by flattening an array of futures ([Future<[Demand]>]) into a future with an array of results (Future<[Demand]>).
    /// 9. If no: Throw abort.

    
    func createHandler(_ req: Request) throws -> Future<[Demand]> { // 1
        
        let user = try req.requireAuthenticated(User.self) // 2
        return try req.content.decode(DemandOfferData.self).flatMap(to: [Demand].self) { data in // 3
            
            return Ad.query(on: req).filter(\Ad.id == data.adID).first().flatMap(to: [Demand].self) { foundAd in // 4
                
                guard let existingAd = foundAd else {throw Abort(.notFound)} // 5
                
                if try user.requireID() == existingAd.userID { // 6
                    return try data.strings.map{Demand(demand: $0, adID: try existingAd.requireID()).save(on: req)}.flatten(on: req) // 7
        
                } else { // 8
                    throw Abort(.forbidden)
                }
            }
        }
    } 
}


