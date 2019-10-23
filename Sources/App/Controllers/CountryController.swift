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
         */
        
        let countryRoutes = router.grouped("countries")
        let tokenAuthMiddleware = User.tokenAuthMiddleware() // 1
        let guardAuthMiddleware = User.guardAuthMiddleware() // 2
        let tokenAuthGroup = countryRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware) // 3
        let adminGroup = tokenAuthGroup.grouped(AdminMiddleware()) // 4
        
        // Create a new route path for the api/ads
        // - Grouped Route (/api/ads) +  Request Type (POST, GET, PUT, DELETE) (+ Path component + Method)
   
        // MARK: - OPEN ACCESS
        //
        // 1. Get Request - Retrieve all Countries
        // 2. Get Request - Get the Departments of the Country
        // 3. Get Request - Get all the countries with all their departments
        countryRoutes.get(use: getAllHandler) // 1
        countryRoutes.get(Country.parameter, "departments",  use: getDepartmentsHandler) // 2
        countryRoutes.get("departments", use: getCountriesWithDepartments) // 3
        
        // MARK: - ADMIN ACCESS
        //
        // 1. Post Request - Post route with method which creates new Countries. This is Protected.
        // 2. Delete Request - Delete country
        adminGroup.post(use: createHandler) // 1
        adminGroup.delete("delete", Country.parameter, use: deleteCountryHandler) // 2
       
    
        
        
        
    }
    
    // MARK: - Handlers
    
    
    /**
     # Create Country
     
     - Parameters:
        - req: Request
     - Throws: Error
     - Returns: Future : HTTPResponse
     
     1. Function return Future<HTTPResponse>
     2. Decode the request's JSON into an object. This is simple because the Model conforms to Content. Decode returns a Future; use flatMap(to:) to extract the object when decoding completes.
     3. Save the object and transform the status to created.
    */
    func createHandler(_ req: Request) throws -> Future<HTTPResponse> { // 1
        return try req.content.decode(Country.self).flatMap(to: HTTPResponse.self) { country in // 2
            return country.save(on: req).transform(to: HTTPResponse(status: .created)) // 3
        }
    }
    
    /**
    # Retrieve All Countries
     
     - Parameters:
        - req: Request
     - Throws: Error
     - Returns: Future : [Country]
          
    1. Only parameter is request itself
    2. Perform Query to Retrieve All (Fluent adds functions to models to be able to perform queries on them. Provides a thread to perform the work.) Function fetches all Objects from the table and returns an array of Objects
    */
    func getAllHandler(_ req: Request) throws -> Future<[Country]> { // 1
        return Country.query(on: req).all() // 2
    }
    
    
    /**
     # Get Children (departments)
     
    - Parameters:
        - req: Request
    - Throws: Error
    - Returns: Future : [Department]
     
     1. Define a new route handler, getAdsHandler(_:), that returns Future<[Child]>
     2. Fetch the Object specified in the request’s parameters and unwrap the returned future.
     3. Use the computed property to get the children using a Fluent query to return all the departments in ascending order.
    */
    func getDepartmentsHandler(_ req: Request) throws -> Future<[Department]> { // 1
        return try req.parameters.next(Country.self).flatMap(to: [Department].self) { country in // 2
            try country.departments.query(on: req).sort(\.departmentNumber, .ascending).all() // 3
        }
    }
    
    /**
     # Delete Country by ID
     - Parameters:
        - req: Request
     - Throws: Error
     - Returns: Response
     
     1. Method to DELETE to that returns Future<Response>
     2. Extract the Object to delete from the request’s parameters.
     3. Delete the Object using delete(on:). Instead of requiring you to unwrap the returned Future, Fluent allows you to call delete(on:) directly on that Future. This helps tidy up code and reduce nesting. Fluent provides convenience functions for delete, update, create and save.
     4. Transform the result into a 204 No Content response. This tells the client the request has successfully completed but there’s no content to return.
     */
    
    func deleteCountryHandler(_ req: Request) throws -> Future<Response> { // 1
        return try req.parameters.next(Country.self) // 2
            .delete(on: req) // 3
            .transform(to: Response(http: HTTPResponse(status: .noContent), using: req)) // 4
    }
    
    /**
     # Route hadnler to get all the countries with their departments
     - Parameters:
            - req: Request
    - Throws: Error
    - Returns: Future<[CountryWithDepartments]>
     
     1.  Make a query to the Country table and return all.
     2.  Use map(:) to transform each country into Future<[CountryWithDepartments]>.
     3. Get all the departments of the country.
     4. Populate <CountryWithDepartments>
     5. Flatten the array of futures to return the array of all countries with all their departments.
     
     */
    func getCountriesWithDepartments(_ req: Request) throws -> Future<[CountryWithDepartments]> {
        
        return Country.query(on: req).all().flatMap(to: [CountryWithDepartments].self) { countries in // 1
            try countries.map { country in // 2
                try country.departments.query(on: req).sort(\Department.departmentNumber, .ascending).all().map{ departments in // 3
                    CountryWithDepartments(country: country, departments: departments) // 4
                }
            }.flatten(on: req) // 5
        }
    }
     
}
