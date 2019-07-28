//
//  AdController.swift
//  App
//
//  Created by Sötnos on 03/07/2019.
//

import Vapor
import Fluent
import Foundation
import Authentication
import Crypto
// Define different route handlers. To access routes you must register handlers with the router. A simple way to do this is to call the functions inside your controller froum routes.swift

struct AdController : RouteCollection {
   
    // MARK : - Register Routes
    
    func boot(router: Router) throws {

        // API end point which handles all ad routes
        let adRoutes = router.grouped("api", "ads")
        
        // Create a TokenAuthenticationMiddleware for User. This uses BearerAuthenticationMiddleware to extract the bearer token out of the request. The middleware then converts this token into a logged in user.
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let tokenAuthGroup = adRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        
    
        /*
         
         
         Create a new route path for the api/ads
         
         - Grouped Route (/api/ads) +  Request Type (POST, GET, PUT, DELETE) (+ Path component + Method)
         
         1. Post Request - Post route with method which creates new ads. This Connects the “create ad” path to createHandler() through this tokenAuthGroup middleware group.
         2. Get Request - Retrieve all Ads
         3. Get Request - Retrieve Ad by its ID (The route takes the Ad's id property as the final path segment)
         4. Delete Request - Delete item by its ID (The route takes the Ad's id property as the final path segment)
         5. Get Request - Get the City(parent) of the Object(child)
         6. Post Request - Attach categories to ad
         7. Get Request - Get the categories of the ad
         8. Delete Request - Remove the sibling relationship between objects
         9. Post Request - Attach city to ad
         10. Get Request - Get the Contact (parent)
         11. Get Request - Get the demands of the ad (children)
         12. Get Request - Get the offers of the ad (children)
         13. Put Request - Update the Ad
         
         */
        
        tokenAuthGroup.post(use: createHandler) // 1
        tokenAuthGroup.get(use: getAllHandler) // 2
        adRoutes.get(Ad.parameter, use: adHandler) // 3
        tokenAuthGroup.delete(Ad.parameter, use: deleteHandler) // 4
        adRoutes.get(Ad.parameter, "city", use: getCityHandler) // 5
//        adRoutes.post(Ad.parameter, "categories", Category.parameter, use: addCategoriesHandler) // 6
//        adRoutes.get(Ad.parameter, "categories", use: getCategoriesHandler) // 7
//        adRoutes.delete(Ad.parameter, "categories", Category.parameter, use: removeCategoriesHandler) // 8
        adRoutes.get(Ad.parameter, "contact", use: getContactHandler) // 10
//       adRoutes.post("images", Ad.parameter, use: addProfilePicturePostHandler)
        
        
        // We need these apis in our editAd.js
        adRoutes.get(Ad.parameter, "demands", use: getDemandsHandler) // 11
        adRoutes.get(Ad.parameter, "offers", use: getOffersHandler) // 12
        tokenAuthGroup.put(Ad.parameter, use: updateHandler) // 13
 //       adRoutes.get("all", Department.parameter, use: getAdOfPerimeter)
     //   adRoutes.get("test", Department.parameter, use: test)
        adRoutes.get("all", Department.parameter, use: getAdsOfPerimeter)
       
    }
    // MARK: - HANDLERS
    
    /*
     Create Ad
     1. Function that returns Future<Ad>
     2. Decode the request's JSON into an Ad. This is simple because Ad conforms to Content. Decode returns a Future; use flatMap(to:) to extract the ad when decoding completes.
     3. Save object.
     */
    
    
    func createHandler(_ req: Request) throws -> Future<Ad> {
        
        return try req.content.decode(Ad.self).flatMap(to: Ad.self) { ad in // 1
            return ad.save(on: req) // 3
            
        }
        
    }
    
    /*
     Function to the Perimeter and all the Cities in the Perimeter
     1. Select the Department
     2. Get the Perimeter of the Department
     3. Get all the cities inside of the Perimeter
     4. Loop cities and add all the ads of the cities
     5. Get the Demand, Contact, Offer,
     */
    
   
    
    /* Retrieve All Ads
     1. Only parameter is request itself
     2. Perform Query to Retrieve All (Fluent adds functions to models to be able to perform queries on them. Provides a thread to perform the work.) Function fetches all Objects from the table and returns an array of Objects
     */
    
    func getAllHandler(_ req: Request) throws -> Future<[Ad]> { // 1
        
        let user = try req.requireAuthenticated(User.self)
        print(user)
        
        return Ad.query(on: req).all() // 2
        
    }
    
    /*
     Retrieve a Single Add
     1. Get Object based on their ID
     2. Extract the object from the request using parameters. This computed property performs all the work necessary to get the object from the database. It also handles the error cases when the object doesn’t exist or the ID type is wrong (for example, when you pass it an integer when the ID is a UUID).”
     */
    
    func getHandler(_ req: Request) throws -> Future<Ad> { // 1
        return try req.parameters.next(Ad.self) // 2
    }
    
    /*
     Delete by ID
     1. Method to DELETE to /api/ads/<ID> that returns Future<HTTPStatus>
     2. Extract the Object to delete from the request’s parameters.
     3. Delete the Object using delete(on:). Instead of requiring you to unwrap the returned Future, Fluent allows you to call delete(on:) directly on that Future. This helps tidy up code and reduce nesting. Fluent provides convenience functions for delete, update, create and save.
     4. Transform the result into a 204 No Content response. This tells the client the request has successfully completed but there’s no content to return.
     */
    
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> { // 1
        return try req.parameters.next(Ad.self) // 2
            .delete(on: req) // 3
            .transform(to: .noContent) // 4
    }
    
    
    /// MARK: - RELATIONSHIP HANDLERS
    
    
    /*
     Get Parent (Contact)
     1. Define a new route handler, getDepartmentHandler(_:), that returns Future<Contact>.
     2. Fetch the object specified in the request’s parameters and unwrap the returned future.
     3. Use the computed property to get the child’s parent.
     */
    
    func getContactHandler(_ req: Request) throws -> Future<Contact> { // 1
        return try req.parameters.next(Ad.self).flatMap(to: Contact.self) { ad in // 2
            ad.contact.get(on: req) // 3
        }
    }
    
    /*
     Get Parent (City)
     1. Define a new route handler, getDepartmentHandler(_:), that returns Future<City>.
     2. Fetch the object specified in the request’s parameters and unwrap the returned future.
     3. Use the computed property to get the child’s parent.
     */
    
    func getCityHandler(_ req: Request) throws -> Future<City> { // 1
        return try req.parameters.next(Ad.self).flatMap(to: City.self) { ad in // 2
            ad.city.get(on: req) // 3
            
        }
    }
    
    /*
     Get children (Demand)
     1. Define a new route handler, getDemandsHandler(_ :) that return Future<Demand>.
     2. Fetch the object specified in the reques't parameters and unwrap the returned future.
     3. Use the property to query all the children.
     
     */
    
    func getDemandsHandler(_ req: Request) throws -> Future<[Demand]> {
        return try req.parameters.next(Ad.self).flatMap(to: [Demand].self) { ad in
            try ad.demands.query(on: req).all()
        }
    }
    
    
    
    /*
     Get children (Offer)
     1. Define a new route handler, getOfferssHandler(_ :) that return Future<Offer>.
     2. Fetch the object specified in the reques't parameters and unwrap the returned future.
     3. Use the property to query all the children.
     
     */
    
    func getOffersHandler(_ req: Request) throws -> Future<[Offer]> {
        return try req.parameters.next(Ad.self).flatMap(to: [Offer].self) { ad in
            try ad.offers.query(on: req).all()
        }
    }
    
    /*
     Update Ad
     
     1. Function that returns Future<Ad>.
     2. Use flatMap(to:_:_:), the dual future form of flatMap, to wait for both the parameter extraction and content decoding to complete. This provides both the ad from the database and ad from the request body to the closure.
     3. Update the ad’s properties with the new values.
     4. Save the ad and return the result.
     */
    
    
    func updateHandler(_ req: Request) throws -> Future<Ad> { // 1
        // 2
        return try flatMap(
            to: Ad.self,
            req.parameters.next(Ad.self),
            req.content.decode(Ad.self)
            // 3
        ) { ad, updatedAd in
            ad.generosity = updatedAd.generosity
            ad.note = updatedAd.note
            ad.cityID = updatedAd.cityID
            ad.contactID = updatedAd.contactID
            ad.images = updatedAd.images
            ad.show = updatedAd.show
            // 4
            return ad.save(on: req)
        }
    }
    
    // MARK: - GET ALL THE ADS OF THE PERIMETER
    /*
     GET ADS OF THE PERIMETER
     1. Define a route handler that returns Future<AdsOfPerimeterData>
     2. Extact the Department from the request's parameters and unwrap the result.
     3. Query departments(sibling) of the department from the database and unwrap the future.
     4. Create a temporal array to store departments so we are able to manipulate the array.
     5. Insert the selected department to the array of departments (0 = the first so the user will see his/her department at first).
     6. Create an array of arrays of cities by iterating departments -array trough to query children(cities) of the each element(department) in the departments array.
     7. Flattens an array of futures(cities) into a future with an array of results(city); [EventLoopFuture<[City]>] -> EventLoopFuture<[[City]]>.
     8. Return and flatMap flattenCities.
     9. Merge the array of arrays into one array.
     10. Create an array of arrays of ads by iterating cities -array trough to query children(ads) of the each element(city) in the arrayOfCities and sorting them based on the generosity value (the most generous at first). Limit the result by 50.
     11. Flattens an array of futures(ads) into a future with an array of results(ads); [EventLoopFuture<[Ad]>] -> EventLoopFuture<[[Ad]]>.
     12. Return and flatMap flattenAds so we can access the models.
     13. Merge the array of arrays into one array.
     14. Return an array of <AdObject> which are created on the closure by iterating each element arrayOfAds and using the element to fetch the data of that element to create AdObject.
     15. Ensure that the id of the ad is not nil. If it's nil, throw an Abort.
     16. Query demands(children) of the ad.
     17. Query offers(children) of the ad.
     18. Get the city(parent) of the ad.
     19. Closure to execute demand, offer, city -futures. Returns Future<AdObject>. Calls the supplied callback when all three futures have completed.
     20. Query the parent(department) of the city and the result returns Future<AdObject>
     20. Get the department of the city (parent) from the request.
     21. Create and return <AdObject> using the data.
     22. Flatten an array of futures into a future with an array of results.
     23. Map a Future<[AdObject]> to a Future<AdsOfPerimeterData>.
     24. Inside the closure create <AdsOfPerimeterData>.

     */
    func getAdsOfPerimeter(_ req: Request) throws -> Future<AdsOfPerimeterData> { // 1.

        return try req.parameters.next(Department.self).flatMap(to: AdsOfPerimeterData.self) { department in // 2.

            return try department.departmentInsideOfPerimeters.query(on: req).all().flatMap(to: AdsOfPerimeterData.self) { perimeter in // 3.

                var departments = perimeter // 4.
                departments.insert(department, at: 0) // 5.
                let cities = try departments.map{try $0.cities.query(on: req).all()} // 6.
                let flattenCities = cities.flatten(on: req) // 7.

                return flattenCities.flatMap(to: AdsOfPerimeterData.self) { arrayOfArraysOfCities in // 8.

                    let arrayOfCities = arrayOfArraysOfCities.flatMap {$0} // 9.
                    let ads = try arrayOfCities.map{try $0.adsOfCity.query(on: req).filter(\.show == true).sort(\.generosity, .ascending).range(..<50).all() } // 10.
                    let flattenAds = ads.flatten(on: req) // 11.

                    return flattenAds.flatMap(to:AdsOfPerimeterData.self) { arrayOfArrayOfAds in // 12.

                        let arrayOfAds = arrayOfArrayOfAds.flatMap {$0} // 13.
        
                        let adObjects = try arrayOfAds.map { ad  -> Future<AdObject> in // 14.
                        
                            guard let adID = ad.id else {throw Abort(.internalServerError)} // 15.
                            let demands = Demand.query(on: req).filter(\Demand.adID == adID).all() // 16.
                            let offers = Offer.query(on: req).filter(\Offer.adID == adID).all() // 17.
                            let city = ad.city.get(on: req) // 18.
                            
                            return flatMap(to: AdObject.self, demands, offers, city) { demands, offers, city in // 19.
                            
                                return city.department.get(on: req).map(to: AdObject.self) { dep in // 20.
                                    
                                    AdObject(note: ad.note, adID: adID,  demands: demands, offers: offers, city: city, department: dep) // 21.
                                }
                            }
                        }
                        
                        let flattenAdObjects = adObjects.flatten(on: req) // 22.
                        return flattenAdObjects.map(to: AdsOfPerimeterData.self) { finalAdObjectArray in // 23.
                            AdsOfPerimeterData(ads: finalAdObjectArray, selectedDepartment: department) // 24.
                        }
                    }
                }
            }
        }
    }
    
    /*
     GET ONE AD
     1. Declare a new route handler that returns Future<AdData>
     2. Extract the ad from the request's parameters and unwrap the result.
     3. Get the ad’s demands using the computed property.
     4. Get the ad’s offers using the computed property.
     5. Return ad's hearts (children) and unwrap the result.
     6. Get the ad's city.
     7. Call the supplied callback when all four futures have completed and return Future<AdData>.
     8. Get the city's department using the get function and return Future<AdData>.
     9. Create AdData with data we fetched from the database.
     */
    
    func adHandler(_ req: Request) throws -> Future<AdData> { // 1.
        
        return try req.parameters.next(Ad.self).flatMap(to: AdData.self) { ad in // 2.
            
            let demands = try ad.demands.query(on: req).all() // 3.
            let offers = try ad.offers.query(on: req).all() // 4.
            let hearts = try ad.hearts.query(on: req).all() // 5.
            let city = ad.city.get(on: req) // 6.
            return flatMap(to: AdData.self, demands, offers, city, hearts) { demands, offers, city, hearts in // 7.
                
                return city.department.get(on: req).map(to: AdData.self) { department in // 8.
                    
                     AdData(note: ad.note, adID: try ad.requireID(), demands: demands, offers: offers, department: department, city: city, hearts: hearts.count) // 9.
                }
            }
        }
    }
    
}






    /*
     1. Get the parameter from the request and unwrap it
     2. Unwrap the id
     3. Create a query on the Ad table.
     4. Join the City table to the Ad using the shared value - the city's ID.
     5. Filter cities: Take only the cities which has the departmentID same as the selected department has
     6. Also decode the reuslt from the query into users.
     7. When future resolves, it returns an array of tuples containing the ads and cities.
     8. Use map(_:) to transform eacg tuple into AdWithUser
     9. Create AdWithCity from the data returned.
     
     
     */
    
////
////    /// Join ad + offer
//func citiesWithDepartments(_ req: Request, ad: Ad) throws -> Future<[CityWithDepartment]> {
//        // Get the department
//
//
//            guard let id = ad.id else {throw Abort(.internalServerError)} // unwrap
//
//            return City.query(on: req) // 3
//                .join(\Department.id, to: \City.departmentID) // 4
//                .filter(\City.a == id) // 5
//                .alsoDecode(City.self).all() // 6
//                .map(to: [AdWithCity].self) { adCityPairs in // 7
//                adCityPairs.map { ad, ctiy -> AdWithCity in // 8
//                    AdWithCity(ad: ad, city: ctiy) // 9
//
//            }
//        }
//    }


/*
 AdsOfPerimeterData
 - Array of AdObjects
 - Department what was used to make a query
 */
struct AdsOfPerimeterData : Content {
    let ads : [AdObject]
    let selectedDepartment : Department
}

/*
 A New Datatype : AdObject
 - Note of the Ad
 - Demands of the Ad
 - Offers of the Ad
 - City of the Ad
 - Department of the City
 */
struct AdObject : Content {
    let note : String
    let adID : UUID
    let demands : [Demand]
    let offers : [Offer]
    let city : City
    let department : Department
}

/*
 A New Datatype : AdData
 - Note of the Ad
 - Demands of the Ad
 - Offers of the Ad
 - City of the Ad
 - Department of the City
 - Count of the Hearts of the Ad
 */

struct AdData : Content {
    let note : String
    let adID : UUID
    let demands : [Demand]
    let offers : [Offer]
    let department : Department
    let city : City
    let hearts : Int
    
    
    
}
