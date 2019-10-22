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
        let standardGroup = departmentRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware, StandardUserMiddleware())
        
        /*
        // Create a new route path
        // Grouped Route (/api/deparment) +  Request Type (POST, GET, PUT, DELETE) (+ Path component + Method)
         
         
         9. Put Request : Remove departmnent from the relationship
         */
        
        // MARK: - STANDARD ACCESS
        //
        // 1. Get Request : Retrieve all Departments
        // 2. Get Reguest : Department by their ID (The route takes the Department's id property as the final path segment)
        // 3. Get Request : Sorted departments (sorted based on the department_number of the object)
        standardGroup.get(use: getAllHandler) // 1
        standardGroup.get(Department.parameter, use: getHandler) // 2
        standardGroup.get("sorted", use: sortedHandler) // 3
        
        // MARK: - ADMIN ACCESS
        //
        // 1. Post Request : route with method which creates new ads
        // 3. Post Request : /api/departments/<DEPARTMENT_ID>/perimeter/<DEPARTMENT_ID> to adDepartmentsHandler(_:) - Creates a sibling relationship between the department with ID X and the department with ID Y.
        // 4. Get Request : /api/departments/<DEPARTMENT_ID>/perimeter to get the departments inside of the Perimeter of the Selected Department
        // 5. Delete Request : Delete department
        adminGroup.post(use: createHandler) // 1
        adminGroup.post("perimeter", Department.parameter, use: addDepartmentsHandler) // 3
        adminGroup.get(Department.parameter, "perimeter", use: getDepartmentsOfPerimeter) // 4
        adminGroup.delete("delete", Department.parameter, use: deleteDepartmentHandler) // 5
        adminGroup.put("delete", Department.parameter, Department.parameter, use: removeDeparmentFromPerimeterHandler) // 6
    
    }
    
    /**
     # Retrieve All Department
     - parameters:
        - req: Request
     - throws: Abort
     - returns: Future [Department]]
     1. Only parameter is request itself
     2. Perform Query to Retrieve All (Fluent ads functions to models to be able to perform queries on them. Provides a thread to perform the work.) Function fetches all Objects from the table and returns an array of Objects
     */
    
    func getAllHandler(_ req: Request) throws -> Future<[Department]> { // 1
        return Department.query(on: req).all() // 2
    }
  
    /**
     # Delete department
      - parameters:
        - req: Request
     - throws: Abort
     - returns: Future Response
     
     1. Return and Extract the deparment from the request's parameter.
     2. Delete model.
     3. Transform to response.
     */
    
    func deleteDepartmentHandler(_ req: Request) throws -> Future<Response> {
        
        return try req.parameters.next(Department.self) // 1
            .delete(on: req) // 2
            .transform(to: Response(http: HTTPResponse(status: .noContent), using: req)) // 3
        
    }
    
    /**
     # Remove department from relationship
      - parameters:
        - req: Request
     - throws: Abort
     - returns: Future Response
     
     1. Return and Extract the deparments from the request's parameter.
     2. Return departmentInsideOfPerimeters of the first departmentl
     3. Remove the second department from the pivot model between the deparmtents.
     4. Transform to response.
     */
    func removeDeparmentFromPerimeterHandler(_ req: Request) throws -> Future<Response> {
        
        return try flatMap(req.parameters.next(Department.self), req.parameters.next(Department.self)) { department, departmentToRemove in // 1
            return department.departmentsInsideOfPerimeter // 2
                .detach(departmentToRemove, on: req) // 3
                .transform(to: Response(http: HTTPResponse(status: .noContent), using: req)) // 4
        }
    }
    
    
    /// # Create Deparment
    ///
    /// - parameters:
    ///   - req: Request
    /// - throws: Abort
    /// - returns: Future HTTPResponse
    ///
    /// 1. Function return Future<HTTPResponse>
    /// 2. Decode the request's JSON into an object. This is simple because the Model conforms to Content. Decode returns a Future; use flatMap(to:) to extract the object when decoding completes.
    /// 3. Save the object and transform the response to HTTPResponseStatus: created.
    
    func createHandler(_ req: Request) throws -> Future<HTTPResponse> { // 1
        return try req.content.decode(Department.self).flatMap(to: HTTPResponse.self) { department in // 2
            print(department.countryID, department.departmentName)
            return department.save(on: req).transform(to: HTTPResponse(status: .created)) // 3
        }
    }

    /**
     # Retrieve a Single Deparment
     
     - parameters:
            - req: Request
     - throws: Abort
     - returns:Future Department
     
     1. Get Object based on their ID
     2. Extract the object from the request using parameters. This computed property performs all the work necessary to get the object from the database. It also handles the error cases when the object doesn’t exist or the ID type is wrong (for example, when you pass it an integer when the ID is a UUID).
     */
    func getHandler(_ req: Request) throws -> Future<Department> { // 1
        return try req.parameters.next(Department.self) // 2
    }
    
    /**
     # Sort Departments
     
     - parameters:
            - req: Request
     - throws: Abort
     - returns: Future Department
     
     1. Perform Query all
     2. Perform Sort, and sort Retrieved Items in ascending order by their departmentNumber property
     */
    
    func sortedHandler(_ req: Request) throws -> Future<[Department]> {
        return Department.query(on: req) // 1
            .sort(\.departmentNumber, .ascending).all() // 2
    }
    
   
    
    /// # Set up the relationship between departments:
    ///
    /// - parameters:
    ///   - req: Request
    /// - throws: Abort
    /// - returns: Future Response
    ///
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
    
    /**
     # Get departments of the perimeter of the department:
     - parameters:
                - req: Request
     - throws: Abort
     - returns: Future DepartmentWithPerimeter
         
     1. Define route handler getDepartmentsInsidePerimeterHandler(_:) returning Future<[Department]>.
     2. Extract the department from the request's parameters and unwrap the returned future.
     3. Use the computed property to get the departments inside the perimeter of the selected Department. Then use a Fluent query to return all the departments.
     */
    
    func getDepartmentsOfPerimeter(_ req: Request) throws -> Future<DepartmentWithPerimeter> { // 1
 
        return try req.parameters.next(Department.self).flatMap(to: DepartmentWithPerimeter.self) { department in // 2
            return try department.departmentsInsideOfPerimeter.query(on: req).sort(\Department.departmentNumber, .ascending).all().map(to: DepartmentWithPerimeter.self) { perimeter in // 3
                return DepartmentWithPerimeter(department: department, perimeter: perimeter)
            
            }
        }
    }
    
}

