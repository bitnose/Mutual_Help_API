//
//  CountryController.swift
//  App
//
//  Created by Sötnos on 03/07/2019.
//

import Foundation
import Vapor
import Fluent
import Authentication

struct CountryController : RouteCollection {
    
    // MARK: - Register Routes
    func boot(router: Router) throws {
    
        /*
         1. Create a TokenAuthenticationMiddleware for User. This uses BearerAuthenticationMiddleware to extract the bearer token out of the request. The middleware then converts this token into a logged in user.
         2. Create an instance of GuardAuthenticationMiddleware which ensures that requests contain valid authorization
         3. Create a tokentAuthGroupt for the routes that need protection.
         4. Create a adminGroup for the routes with admin access.
         
         Create a new route path for the api/ads
         - Grouped Route (/api/ads) +  Request Type (POST, GET, PUT, DELETE) (+ Path component + Method)
         
         1. Post Request - Post route with method which creates new Countries. This is Protected.
         2. Get Request - Retrieve all Countries
         3. Get Request - Get the Departments of the Country
         
         */
        
    
        let countryRoutes = router.grouped("api/countries")
        let tokenAuthMiddleware = User.tokenAuthMiddleware() // 1
        let guardAuthMiddleware = User.guardAuthMiddleware() // 2
        let tokenAuthGroup = countryRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware) // 3
        let adminGroup = tokenAuthGroup.grouped(AdminMiddleware()) // 4
        
        adminGroup.post(use: createHandler) // 1
        countryRoutes.get(use: getAllHandler) // 2
        countryRoutes.get(Country.parameter, "departments",  use: getDepartmentsHandler) // 3
    
        
        
        
    }
    
    // MARK: - Handlers
    
    
    /// Create Country
    /// 1. Function return Future<HTTPResponse>
    /// 2. Decode the request's JSON into an object. This is simple because the Model conforms to Content. Decode returns a Future; use flatMap(to:) to extract the object when decoding completes.
    /// 3. Save the object and transform the status to created.
    
    func createHandler(_ req: Request) throws -> Future<HTTPResponse> { // 1
        return try req.content.decode(Country.self).flatMap(to: HTTPResponse.self) { country in // 2
            return country.save(on: req).transform(to: HTTPResponse(status: .created)) // 3
        }
    }
    
    /// Retrieve All Countries
    /// 1. Only parameter is request itself
    /// 2. Perform Query to Retrieve All (Fluent adds functions to models to be able to perform queries on them. Provides a thread to perform the work.) Function fetches all Objects from the table and returns an array of Objects
    
    func getAllHandler(_ req: Request) throws -> Future<[Country]> { // 1
        return Country.query(on: req).all() // 2
    }
    
    
    /// Get Children
    /// 1. Define a new route handler, getAdsHandler(_:), that returns Future<[Child]>
    /// 2. Fetch the Object specified in the request’s parameters and unwrap the returned future.
    /// 3. Use the computed property to get the children using a Fluent query to return all the departments in ascending order.
    
    func getDepartmentsHandler(_ req: Request) throws -> Future<[Department]> { // 1
        return try req.parameters.next(Country.self).flatMap(to: [Department].self) { country in // 2
            try country.departments.query(on: req).sort(\.departmentNumber, .ascending).all() // 3
        }
    }
}
