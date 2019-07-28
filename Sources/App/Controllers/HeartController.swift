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
        heartRoutes.post(use: createUncreateHandler) // 1
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
    
/// Create Heart / Delete Heart
/// 1. Function which returns Future<HTTPStatus>
/// 2. Decode the content of the request to Heart object and map it to Future<HTTPStatus>.
/// 3. Token of the heart.
/// 4. Id of the Ad(parent) of the heart.
/// 5. Query all the hearts and get the first (and only one) which has the same values (token and adID) as the decoded heart has. Map it to Future<HTTPStatus>.
/// 6. If the query finds the heart ie it exists already in the database.
/// 7. Delete the found heart and map it to Future<HTTPStatus>.
/// 8. Return .noContent.
/// 9. If the heart wasn't found.
/// 10. Save the heart to database and map it to Future<HTTPStatus>.
/// 11. Return .created.
    
    func createUncreateHandler(_ req: Request) throws -> Future<HTTPStatus> { // 1
        
        return try req.content.decode(Heart.self).flatMap(to: HTTPStatus.self) { heart in // 2
            let token = heart.token // 3
            let adID = heart.adID // 4
            
            return Heart.query(on: req).filter(\Heart.token == token).filter(\Heart.adID == adID).first().flatMap(to: HTTPStatus.self) { existingHeart in // 5
               
                if let foundHeart = existingHeart { // 6
                    return foundHeart.delete(on: req).map(to: HTTPStatus.self) { heart in // 7
                        return .noContent // 8
                    }
                } else { // 9
                    return heart.save(on: req).map(to: HTTPStatus.self) { heart in // 10
                        return .created
                    }
                }
            }
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
