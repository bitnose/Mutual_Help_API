//
//  AdUserMiddleware.swift
//  App
//
//  Created by Sötnos on 14/09/2019.
//

/// TODO: MAYBE USELESS

import Foundation
import Vapor

/// # Custom AdUserMiddleware looks if the user owns the ad what she/he tries to manipulate.
/// This method will be called with each Request that passes through this middleware.
/// 1. Respond -method takes the request and responds to the request. Throws if errors occur.
/// 2. Get the authenticated user from the request.
/// 3. Get the ad from the request's parameters. Map the executed closure to Future<Response>.
/// 4. Look if the user id and the id of the ad's owner matches.
/// 5. If yes: Chain to the next middleware normally.
/// 6. If no: Throw an abort (fordidden).
final class AdUserMiddleware : Middleware {
    
    func respond(to request: Request, chainingTo next: Responder) throws -> EventLoopFuture<Response> { // 1
        
        let requestUser = try request.requireAuthenticated(User.self) // 2
        
        return try request.parameters.next(Ad.self).flatMap(to: Response.self) { ad in // 3
  
            if try requestUser.requireID() ==  ad.userID { // 4
                print("User owns the ad")
                 return try next.respond(to: request)
            } else { print("User doesn't have the rights to execute this action"); throw Abort(.forbidden)}
        }
    }
}
