//
//  DepartmentController.swift
//  App
//
//  Created by Sötnos on 06/07/2019.
//

import Foundation
import Vapor
import Fluent

// Define different route handlers. To access routes you must register handlers with the router. A simple way to do this is to call the functions inside your controller froum routes.swift

struct DepartmentController : RouteCollection {
    
    // MARK : - Register Routes
    
    func boot(router: Router) throws {
        
        /// 1. Create a TokenAuthenticationMiddleware for User. This uses BearerAuthenticationMiddleware to extract the bearer token out of the request. The middleware then converts this token into a logged in user.
        /// 2. Create an instance of GuardAuthenticationMiddleware which ensures that requests contain valid authorization
        /// 3. Create a adminGroup for the routes with admin access. 

        let departmentRoutes = router.grouped("api/departments")
        let tokenAuthMiddleware = User.tokenAuthMiddleware() // 1
        let guardAuthMiddleware = User.guardAuthMiddleware() // 2
        let adminGroup = departmentRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware, AdminMiddleware()) // 3
        
        /*
         Create a new route path
         Grouped Route (/api/deparment) +  Request Type (POST, GET, PUT, DELETE) (+ Path component + Method)
         
         1. Post Request : route with method which creates new ads
         2. Get Request : Retrieve all Departments
         3. Get Reguest : Department by their ID (The route takes the Department's id property as the final path segment)
         4. Get Request : Sorted departments (sorted based on the department_number of the object)
         5. Get Request : Get children (Ads) of the Object (Department)
         6. Post Request : /api/departments/<DEPARTMENT_ID>/perimeter/<DEPARTMENT_ID> to adDepartmentsHandler(_:) - Creates a sibling relationship between the department with ID X and the department with ID Y.
         7. Get Request : /api/departments/<DEPARTMENT_ID>/perimeter to get the departments inside of the Perimeter of the Selected Department
         */
        
        adminGroup.post(use: createHandler) // 1
        departmentRoutes.get(use: getAllHandler) // 2
        departmentRoutes.get(Department.parameter, use: getHandler) // 3
        departmentRoutes.get("sorted", use: sortedHandler) // 4
        departmentRoutes.get(Department.parameter, "cities", use: getCitiesHandler) // 5
        adminGroup.post("perimeter", Department.parameter, use: addDepartmentsHandler) // 6
        departmentRoutes.get(Department.parameter, "perimeter", use: getDepartmentsOfPerimeter) // 7
    
    }
    
    // MARK: - HANDLERS
    
    /// Create Deparment
    /// 1. Function return Future<HTTPResponse>
    /// 2. Decode the request's JSON into an object. This is simple because the Model conforms to Content. Decode returns a Future; use flatMap(to:) to extract the object when decoding completes.
    /// 3. Save the object and transform the response to HTTPResponseStatus: created.
    
    func createHandler(_ req: Request) throws -> Future<HTTPResponse> { // 1
        return try req.content.decode(Department.self).flatMap(to: HTTPResponse.self) { department in // 2
            print(department.countryID, department.departmentName)
            return department.save(on: req).transform(to: HTTPResponse(status: .created)) // 3
        }

    }
    
 
    
    /*
     Retrieve All Department
     1. Only parameter is request itself
     2. Perform Query to Retrieve All (Fluent ads functions to models to be able to perform queries on them. Provides a thread to perform the work.) Function fetches all Objects from the table and returns an array of Objects
     */
    
    func getAllHandler(_ req: Request) throws -> Future<[Department]> { // 1
        return Department.query(on: req).all() // 2
    }
    
    /*
     Retrieve a Single Deparment
     1. Get Object based on their ID
     2. Extract the object from the request using parameters. This computed property performs all the work necessary to get the object from the database. It also handles the error cases when the object doesn’t exist or the ID type is wrong (for example, when you pass it an integer when the ID is a UUID).
     */
    func getHandler(_ req: Request) throws -> Future<Department> { // 1
        return try req.parameters.next(Department.self) // 2
    }
    
    /*
     Sort Objects
     1. Perform Query all
     2. Perform Sort, and sort Retrieved Items in ascending order by their departmentNumber property
     */
    
    func sortedHandler(_ req: Request) throws -> Future<[Department]> {
        return Department.query(on: req) // 1
            .sort(\.departmentNumber, .ascending).all() // 2
    }
    
    /*
     Get Children
     1. Define a new route handler, getAdsHandler(_:), that returns Future<[Ads]>
     2. Fetch the Object specified in the request’s parameters and unwrap the returned future.
     3. Use the computed property to get the children using a Fluent query to return all the ads.
     */
    
    func getCitiesHandler(_ req: Request) throws -> Future<[City]> { // 1
        return try req.parameters.next(Department.self).flatMap(to: [City].self) { department in // 2
            try department.cities.query(on: req).all() // 3
        }
    }
    
    /// Set up the relationship between departments:
    /// 1. Define a new route handler addDepartmentsHandler(_:), that returns a Future<HTTPStatus>.
    /// 2. Use map(to:_:_:) to extract a department from the request's parameter, decode the content of the request to be an array of UUIDs.
    /// 3. Iterate the array of IDs trough one by one.
    /// 4. In the do-catch-block call the another method to create a pivot model between two departments (add a sibling relationship between the models).
    /// 5. If errors occur catch them and print out.
    /// 6. Transform the future to a 201 Created response.
    func addDepartmentsHandler(_ req: Request) throws -> Future<Response> { // 1
        // 2
        return try map(to: Response.self, req.parameters.next(Department.self), req.content.decode([UUID].self)) { department, departmentIDs in
            // 3
            for id in departmentIDs {
                do { // 4
               _ = try Department.addPivot(neighbourID: id, to: department, on: req)
                } catch let error { // 5
                    print(error)
                }
            }
            return req.response(http: HTTPResponse(status: .created)) // 6
        }
    }
    
    /*
     Get departments of the perimeter of the department:
     1. Define route handler getDepartmentsInsidePerimeterHandler(_:) returning Future<[Department]>.
     2. Extract the department from the request's parameters and unwrap the returned future.
     3. Use the computed property to get the departments inside the perimeter of the selected Department. Then use a Fluent query to return all the departments.
     */
    
    func getDepartmentsOfPerimeter(_ req: Request) throws -> Future <[Department]> { // 1
        
        return try req.parameters.next(Department.self).flatMap(to: [Department].self) { department in // 2
            try department.departmentsInsideOfPerimeter.query(on: req).all() // 3
        }
    }
    
}


