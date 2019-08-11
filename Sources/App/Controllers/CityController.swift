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
        
        /// 1. Create a TokenAuthenticationMiddleware for User. This uses BearerAuthenticationMiddleware to extract the bearer token out of the request. The middleware then converts this token into a logged in user.
        /// 2. Admin group for the protected routes (user must have an admin access)
        let cityRoutes = router.grouped("api/cities")
        // 1
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let adminGroup = cityRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware, AdminMiddleware()) // 2
       
        /*
         Create a new route path for the api/ads
     
         
         - Grouped Route (/api/ads) +  Request Type (POST, GET, PUT, DELETE) (+ Path component + Method)
         
         1. Post Request - Post route with method which creates new Cities
         2. Get Request - Retrieve all Cities
         3. Get Request - Get the Ads of the City
         4. Get Request - Get the City with ID
         */
        
        
        adminGroup.post(use: createHandler) // 1
        cityRoutes.get(use: getAllHandler) // 2
        cityRoutes.get(City.parameter, "ads",  use: getAdsHandler) // 3
        cityRoutes.get("id", UUID.parameter, use: getCityWithDepartmentHandler) // 4
        
        
        
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
    
    /// Get city with ID Handler returns Future<CityWithDepartment>
    /// 1. Fetch the Object specified in the request’s parameters and unwrap the returned future.
    /// 2. Use the join to fetch the parent.
    /// 3. Filter with the city ID.
    /// 4. Return city object.
    
    
    
    
    
    
    /*
     1. Handler fetches the City with ID and its Department (returns Future<CityWithDepartment>)
     2. Get the UUID parameter from the request and unwrap it.
     3. Create a query on the City table.
     4. Join the City table to the Department table using the shared value - the department's ID.
     5. Filter cities: Take only the cities which has the cityID same as the UUID parameter from the request is.
     6. Also decode the result from the query into departments.
     7. When future resolves, it returns an array of tuples containing the cities and departments.
     8. Get the first (and only one) object from the array. If "guard-let-else" resolves as an error throw an Abort.
     9. Return and Create CityWithDepartment from the data returned.
     */

    func getCityWithDepartmentHandler(_ req: Request) throws -> Future<CityWithDepartment> { // 1
        
        let id = try req.parameters.next(UUID.self) // 2
        print(id)
        return City.query(on: req) // 3
            .join(\Department.id, to: \City.departmentID) // 4
            .filter(\City.id == id) // 5
            .alsoDecode(Department.self).all() // 6
            .map(to: CityWithDepartment.self) { cityDepartmentPairs in // 7
                guard let cityObject = cityDepartmentPairs.first else {throw Abort(.notFound)} // 8
                print(cityObject.0.city, cityObject.1.departmentName)
                return CityWithDepartment(city: cityObject.0, department: cityObject.1) // 9
        }
    }
}

/// CityWithDepartment Datatype contains the city and the department of the city
/// - city
/// - department
struct CityWithDepartment : Content {
    let city : City
    let department : Department
}
