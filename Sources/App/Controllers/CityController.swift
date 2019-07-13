//
//  CityController.swift
//  App
//
//  Created by Sötnos on 03/07/2019.
//

import Foundation
import Vapor
import Fluent

struct CityController : RouteCollection {
    
    // MARK: - Register Routes
    func boot(router: Router) throws {
        
        /*
         Create a new route path for the api/ads
         
         - Grouped Route (/api/ads) +  Request Type (POST, GET, PUT, DELETE) (+ Path component + Method)
         
         1. Post Request - Post route with method which creates new Cities
         2. Get Request - Retrieve all Cities
         3. Get Request - Get the Ads of the City
         */
        
        let cityRoutes = router.grouped("api/cities")
        cityRoutes.post(use: createHandler) // 1
        cityRoutes.get(use: getAllHandler) // 2
        cityRoutes.get(City.parameter, "ads",  use: getAdsHandler) // 3
        
        
        
    }
    
    // MARK: - Handlers
    
    /*
     Add City
     1. Function return Future<City>
     2. Decode the request's JSON into an object. This is simple because the Model conforms to Content. Decode returns a Future; use flatMap(to:) to extract the object when decoding completes.
     3. Save the object.
     */
    
    func createHandler(_ req: Request) throws -> Future<City> { // 1
        return try req.content.decode(City.self).flatMap(to: City.self) { city in // 2
            return city.save(on: req) // 3
        }
    }
    //moi
    /* Retrieve All Cities
     1. Only parameter is request itself
     2. Perform Query to Retrieve All (Fluent adds functions to models to be able to perform queries on them. Provides a thread to perform the work.) Function fetches all Objects from the table and returns an array of Objects
     */
    
    func getAllHandler(_ req: Request) throws -> Future<[City]> { // 1
        return City.query(on: req).all() // 2
    }
    
    /*
     Get Children
     1. Define a new route handler, getAdsHandler(_:), that returns Future<[Ad]>
     2. Fetch the Object specified in the request’s parameters and unwrap the returned future.
     3. Use the computed property to get the children using a Fluent query to return all the ads.
     */
    
    func getAdsHandler(_ req: Request) throws -> Future<[Ad]> { // 1
        return try req.parameters.next(City.self).flatMap(to: [Ad].self) { city in // 2
            try city.adsOfCity.query(on: req).all() // 3
        }
    }
}
