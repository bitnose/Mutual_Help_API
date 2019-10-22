//
//  OfferController.swift
//  App
//
//  Created by Sötnos on 03/07/2019.
//

import Foundation
import Vapor
import Fluent

struct OfferController : RouteCollection {
    
    // MARK: - Register Routes
    func boot(router: Router) throws {
        
        
        // Route groups
        // 1. Create a TokenAuthenticationMiddleware for User. This uses BearerAuthenticationMiddleware to extract the bearer token out of the request. The middleware then converts this token into a logged in user.
        // 2. Functionality: Error to throw if the type is not authed.
        // 3. This group of routes requires the user to have an admin access OR standard access.
    
        let demandRoutes = router.grouped("api/offers")
        let tokenAuthMiddleware = User.tokenAuthMiddleware() // 1
        let guardAuthMiddleware = User.guardAuthMiddleware() // 2
        let standardRoutes = demandRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware) // 3
  

        
        /*
         Create a new route path for the api/ads
         
         - Grouped Route (/api/ads) +  Request Type (POST, GET, PUT, DELETE) (+ Path component + Method)
         1. Post Request - Post route with method which creates new offer
         */
        

        standardRoutes.post("create", use: createHandler) // 1
     
        
    }
    
    // MARK: - Handlers

     /// Create Offer
     /// 1. Function returns Future<[Offer]>
     /// 2. Get the authenticated user.
     /// 3. Use flatMap(to:) to extract the objects when decoding completes. Decode the request's JSON into an object. This is simple because the Model conforms to Content. Decode returns a Future;
     ///4. Make a query to the ad table in the database, filter results with the data's adID and return Future<[Offer]>.
     /// 5. Unwrap the result of the query.
     /// 6. Look if the id of the user matches with the creator of the ad.
     /// 7. If yes: Make an array by mapping the given closure over the sequence’s elements. This closure creates an ad model and saves it on the database.
     /// 8. Return Future<[Offer]> by flattening an array of futures ([Future<[Offer>]]) into a future with an array of results (Future<[Offer]>).
     /// 9. If no: Throw abort.

    func createHandler(_ req: Request) throws -> Future<[Offer]> { // 1
        
        let user = try req.requireAuthenticated(User.self) //2
        return try req.content.decode(DemandOfferData.self).flatMap(to: [Offer].self) { data in // 3
            
            return Ad.query(on: req).filter(\Ad.id == data.adID).first().flatMap(to: [Offer].self) { foundAd in // 4
                
                guard let existingAd = foundAd else {throw Abort(.notFound)} // 5
                
                if try user.requireID() == existingAd.userID { // 6
                    return try data.strings.map{Offer(offer: $0, adID: try existingAd.requireID()) // 7
                        .save(on: req)}.flatten(on: req) // 8
                } else { // 9
                    throw Abort(.forbidden)
                }
            }
        }
    }
}
