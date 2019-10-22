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
        
        // 1. Create a TokenAuthenticationMiddleware for User. This uses BearerAuthenticationMiddleware to extract the bearer token out of the request. The middleware then converts this token into a logged in user.
        let cityRoutes = router.grouped("api/cities")
        // 1
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let standardGroup = cityRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
  
        
        // Create a new route path for the api/ads
        // - Grouped Route (/api/ads) +  Request Type (POST, GET, PUT, DELETE) (+ Path component + Method)
        
        // MARK: - OPEN ACCESS
        
        // 1. Get Request - Get the City with ID

        cityRoutes.get("id", UUID.parameter, use: getCityWithDepartmentHandler) // 1
        
        
        // MARK: - STANDARD ACCESS
        // 1. Post Request - Post route with method which creates new Cities
        standardGroup.post(use: createHandler) // 1
        
        
        
        
    }
    
    // MARK: - Handlers
    
    /**
    # Add City
     - parameters:
         - req: Request
     - throws: Abort
     - Returns: Future  City
     
     1. Function return Future<City>
     2. Decode the request's JSON into an object. This is simple because the Model conforms to Content. Decode returns a Future; use flatMap(to:) to extract the object when decoding completes.
     3. Save the object.
     */
    
    func createHandler(_ req: Request) throws -> Future<City> { // 1
        return try req.content.decode(City.self).flatMap(to: City.self) { city in // 2
            return city.save(on: req) // 3
        }
    }

    
    /**
     # Get City With Department
     - parameters:
         - req: Request
     - throws: Abort
     - Returns: Future  CityWithDepartment
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

