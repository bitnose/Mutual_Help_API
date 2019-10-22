//
//  UserMiddleware.swift
//  App
//
//  Created by Sötnos on 29/08/2019.
//

import Foundation
import Vapor

/// # Custom StandardUserMiddleware looks if user has Standard OR Admin access: If not it sends a forbidden response.
/// 1. Called with each Request that passes through this middleware.
/// 2. Get the user from the request.
/// 3. Looks if a user has standard OR admin access: If not, throw an Abort with forbidden response.
/// 4. Chain to the next middleware normally.
/// 5. Else, throw an Abort. 

final class StandardUserMiddleware : Middleware {
    
    func respond(to request: Request, chainingTo next: Responder) throws -> EventLoopFuture<Response> { // 1
        let requestUser = try request.requireAuthenticated(User.self) // 2
        if requestUser.userType == .standard || requestUser.userType == .admin { // 3
            return try next.respond(to: request) // 4
        } else {throw Abort(.forbidden)} // 5
    }
}
