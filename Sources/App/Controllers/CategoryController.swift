//
//  CategoryController.swift
//  App
//
//  Created by Sötnos on 03/07/2019.
//

//import Vapor
//import Fluent
//import Foundation
//
//// Define different route handlers. To access routes you must register handlers with the router. A simple way to do this is to call the functions inside your controller froum routes.swift
//struct CategoryController : RouteCollection {
//
//    // MARK : - Register Routes
//
//    func boot(router: Router) throws {
//
//        /*
//
//         Create a new route path for the api/ads
//
//         - Grouped Route (/api/categories) +  Request Type (POST, GET, PUT, DELETE) (+ Path component + Method)
//
//         1. Post Request - Post route with method which creates new categories
//         2. Get Request - Retrieve all Categories
//         3. Get Request - Retrieve categories by its ID (The route takes the category's id property as the final path segment)
//         4. Delete Request - Delete object by its ID (The route takes the Categori's id property as the final path segment)
//         5. Get Request - Get the parent of the object
//         6. Get Request - Get the children of the object
//         7. Get Request - Get the siblings of the object
//
//
//         */
//
//        let categoryRoutes = router.grouped("api", "categories")
//        categoryRoutes.post(Category.self, use: createHandler) // 1
//        categoryRoutes.get(use: getAllHandler) // 2
//        categoryRoutes.get(Category.parameter, use: getHandler) // 3
//        categoryRoutes.delete(Category.parameter, use: deleteHandler) // 4
//        categoryRoutes.get(Category.parameter, "maincategory", use: getMainCategoryHandler) // 5
//        categoryRoutes.get(Category.parameter, "subcategories", use: getSubCategoriesHandler) // 6
//        categoryRoutes.get(Category.parameter, "ads", use: getAdsHandler) // 7
//
//
//    }
//
//    // MARK: - HANDLERS
//
//    /*
//     Create Category
//     1. Function has a category  as a parameter which is a decoded category from the request.
//     2. Save the category
//     */
//
//    func createHandler(_ req: Request, category: Category) throws -> Future<Category> { // 1
//        return category.save(on: req) // 2
//    }
//
//    /* Retrieve All Objects
//     1. Only parameter is request itself
//     2. Perform Query to Retrieve All (Fluent ads functions to models to be able to perform queries on them. Provides a thread to perform the work.) Function fetches all Objects from the table and returns an array of Objects
//     */
//
//    func getAllHandler(_ req: Request) throws -> Future<[Category]> { // 1
//        return Category.query(on: req).all() // 2
//    }
//
//    /*
//     Retrieve a Single Object
//     1. Get Object based on their ID
//     2. Extract the object from the request using parameters. This computed property performs all the work necessary to get the object from the database. It also handles the error cases when the object doesn’t exist or the ID type is wrong (for example, when you pass it an integer when the ID is a UUID).”
//     */
//
//    func getHandler(_ req: Request) throws -> Future<Category> { // 1
//        return try req.parameters.next(Category.self) // 2
//    }
//
//    /*
//     Delete by ID
//     1. Method to DELETE to /api/ads/<ID> that returns Future<HTTPStatus>
//     2. Extract the Object to delete from the request’s parameters.
//     3. Delete the Object using delete(on:). Instead of requiring you to unwrap the returned Future, Fluent allows you to call delete(on:) directly on that Future. This helps tidy up code and reduce nesting. Fluent provides convenience functions for delete, update, create and save.
//     4. Transform the result into a 204 No Content response. This tells the client the request has successfully completed but there’s no content to return.
//     */
//
//    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> { // 1
//        return try req.parameters.next(Category.self) // 2
//            .delete(on: req) // 3
//            .transform(to: .noContent) // 4
//    }
//
//    /*
//     Get Parent
//     1. Define a new route handler, getDepartmentHandler(_:), that returns Future<Department>.
//     2. Fetch the object specified in the request’s parameters and unwrap the returned future.
//     3. Use the computed property to get the child’s parent.
//     */
//
//    func getMainCategoryHandler(_ req: Request) throws -> Future<Category> { // 1
//        return try req.parameters.next(Category.self).flatMap(to: Category.self) { category in // 2
//            category.mainCategory.get(on: req) // 3
//        }
//    }
//
//    /*
//     Get Children
//     1. Define a new route handler, that returns Future<[Objects]>
//     2. Fetch the Object specified in the request’s parameters and unwrap the returned future.
//     3. Use the computed property to get the children using a Fluent query to return all the ads.
//     */
//
//    func getSubCategoriesHandler(_ req: Request) throws -> Future<[Category]> { // 1
//        return try req.parameters.next(Category.self).flatMap(to: [Category].self) { category in // 2
//            try category.subCategories.query(on: req).all() // 3
//        }
//    }
//
//    /*
//     Get Ads
//     1. Define a new route handler, that returns Future<[Ad]>.
//     2. Extract the category from the request’s parameters and unwrap the returned future.
//     3. Use the new computed property to get the siblings. Then, use a Fluent query to return all the sibling objects.
//     */
//
//    func getAdsHandler(_ req: Request) throws -> Future<[Ad]> { // 1
//        return try req.parameters.next(Category.self).flatMap(to: [Ad].self) { category in // 2
//            try category.ads.query(on: req).all() // 3
//        }
//    }
//}
//
//

