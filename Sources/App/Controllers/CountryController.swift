//
//  CountryController.swift
//  App
//
//  Created by Sötnos on 03/07/2019.
//

import Foundation
import Vapor
import Fluent

struct CountryController : RouteCollection {
    
    // MARK: - Register Routes
    func boot(router: Router) throws {
        
        /*
         Create a new route path for the api/ads
         
         - Grouped Route (/api/ads) +  Request Type (POST, GET, PUT, DELETE) (+ Path component + Method)
         
         1. Post Request - Post route with method which creates new Countries
         2. Get Request - Retrieve all Countries
         3. Get Request - Get the Departments of the Country
         
         */
        
        let countryRoutes = router.grouped("api/countries")
        countryRoutes.post(use: createHandler) // 1
        countryRoutes.get(use: getAllHandler) // 2
        countryRoutes.get(Country.parameter, "departments",  use: getDepartmentsHandler) // 3
        
        
    }
    
    // MARK: - Handlers
    
    /*
     Create Country
     1. Function return Future<Country>
     2. Decode the request's JSON into an object. This is simple because the Model conforms to Content. Decode returns a Future; use flatMap(to:) to extract the object when decoding completes.
     3. Save the object.
     */
    
    func createHandler(_ req: Request) throws -> Future<Country> { // 1
        return try req.content.decode(Country.self).flatMap(to: Country.self) { country in // 2
             return country.save(on: req) // 3
        }
       
    }
    
    /* Retrieve All Countries
     1. Only parameter is request itself
     2. Perform Query to Retrieve All (Fluent adds functions to models to be able to perform queries on them. Provides a thread to perform the work.) Function fetches all Objects from the table and returns an array of Objects
     */
    
    func getAllHandler(_ req: Request) throws -> Future<[Country]> { // 1
        return Country.query(on: req).all() // 2
    }
    
    
    /*
     Get Children
     1. Define a new route handler, getAdsHandler(_:), that returns Future<[Child]>
     2. Fetch the Object specified in the request’s parameters and unwrap the returned future.
     3. Use the computed property to get the children using a Fluent query to return all the ads.
     */
    
    func getDepartmentsHandler(_ req: Request) throws -> Future<[Department]> { // 1
        return try req.parameters.next(Country.self).flatMap(to: [Department].self) { country in // 2
            try country.departments.query(on: req).all() // 3
        }
    }
}
