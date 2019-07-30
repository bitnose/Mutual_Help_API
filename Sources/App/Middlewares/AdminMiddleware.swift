//
//  AdminMiddleware.swift
//  App
//
//  Created by Sötnos on 30/07/2019.
//

import Foundation
import Vapor

/// Custom AdminMiddleware looks if a user has admin access: If not it sends a forbidden response.
/// 1. Called with each Request that passes through this middleware.
/// 2. Get the user from the request.
/// 3. Looks if a user has admin access: If not, throw an Abort with forbidden response.
/// 4. Chain to the next middleware normally.

final class AdminMiddleware : Middleware {
    
    func respond(to request: Request, chainingTo next: Responder) throws -> EventLoopFuture<Response> { // 1
        let requestUser = try request.requireAuthenticated(User.self) // 2
        guard requestUser.userType == .admin else {throw Abort(.forbidden)} // 3
        return try next.respond(to: request) // 4
    }
}

