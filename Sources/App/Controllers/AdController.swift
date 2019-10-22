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
   
    
    // MARK: - Properties
    private var awsConfig: AwsConfig
    
    // MARK: - Inits
    init(awsConfig: AwsConfig) {
        self.awsConfig = awsConfig
    }

    // MARK: - Register Routes
    func boot(router: Router) throws {

        
        // API end point which handles all ad routes
        let adRoutes = router.grouped("api", "ads")
        
        // Create a TokenAuthenticationMiddleware for User. This uses BearerAuthenticationMiddleware to extract the bearer token out of the request. The middleware then converts this token into a logged in user.
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let tokenAuthGroup = adRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        let adminGroup = tokenAuthGroup.grouped(AdminMiddleware())

        // MARK: - OPEN ACCESS
        /*
         1. Get Request - Retrieve Ad by its ID (The route takes the Ad's id property as the final path segment)
         2. Get Request - Get the City(parent) of the Ad(child)
         3. Get Request - Get the demands of the ad (children)
         4. Get Request - Get the offers of the ad (children)
         5. Get Request - Get ads from the perimeter
        */
        adRoutes.get(Ad.parameter, use: adHandler) // 1
        adRoutes.get(Ad.parameter, "city", use: getCityHandler) // 2
        adRoutes.get(Ad.parameter, "demands", use: getDemandsHandler) // 3
        adRoutes.get(Ad.parameter, "offers", use: getOffersHandler) // 4
        adRoutes.get("all", Department.parameter, use: getAdsOfPerimeter) // 5
        
        
        // MARK: - STANDARD ACCESS
        /*
         1. Post Request - Post route with method which creates new ads. This Connects the “create ad” path to createHandler() through this tokenAuthGroup middleware group.
         2. Delete Request - Delete item by its ID (The route takes the Ad's id property as the final path segment)
         3. Put Request - Update the Ad
         4. Get Request - Get ads from the authenticated user
         5. Post Request - Like/Unlike ad
         */
        
        tokenAuthGroup.post("create", use: createHandler) // 1
        tokenAuthGroup.delete("delete", UUID.parameter, use: deleteHandler) // 2
        tokenAuthGroup.put(UUID.parameter, "update", use: updateAdHandler) // 3
        tokenAuthGroup.get("self", use: getAdsFromUSerHandler) // 4
        tokenAuthGroup.post(Ad.parameter, "like", use: likeUnlikeHandler) // 5
        
        // MARK: - ADMIN ACCESS
        /*
         1. Get Request - Get all the ads with user data
         */
        adminGroup.get("all", use: adWithUserHandler) // 1
        
        
    }
    
    
    // MARK: - HANDLERS

    /// # Create Ad For The User
    /// - parameters:
    ///    - req: Request
    ///    - returns: Future : Ad
    /// - throws: Abort Error
    ///
    /// 1. Function that returns Future<Ad>. Throws if errors occur.
    /// 2. Get the authenticated user from the request.
    /// 3. Unwrap the id of the user.
    /// 4. Decode the request's JSON into an CreateAdData. This is simple because the struct conforms to Content. Decode returns a Future; use flatMap(to:) to extract the data when decoding completes.
    /// 5. Create an ad object from the data and the user id.
    /// 6. Save the user.

    func createHandler(_ req: Request) throws -> Future<Ad> { // 1
        
        let user = try req.requireAuthenticated(User.self) // 2
        guard let id = user.id else {throw Abort(.internalServerError)} // 3

        return try req.content.decode(CreateAdData.self).flatMap(to: Ad.self) { adData in // 4

            let ad = Ad(note: adData.note, cityID: adData.cityID, userID : id) // 5
            return ad.save(on: req) // 6
        }
    }
    
        
    /// # Create Heart / Delete Heart
    /// - parameters:
    ///    - req: Request
    ///    - returns: Future : HTTPStatus
    /// - throws: Abort Error
    ///
    /// 1. Get the if of the authenticated user.
    /// 2. Extract the Ad from the request's parameter and map the future to HTTPStatus.
    /// 3. Get the Id of the Ad(parent) of the heart.
    /// 4. Query all the hearts and get the first (and only one) which has the same values (userID and adID) as the decoded heart has. Map it to Future<HTTPStatus>.
    /// 5. If the query finds the heart ie heart exists already in the database.
    /// 6. Delete the found heart and transform the future to Future<HTTPStatus>.
    /// 7. If the heart wasn't found.
    /// 8. Save the heart to database and transform the future  to Future<HTTPStatus>.
        
        func likeUnlikeHandler(_ req: Request) throws -> Future<HTTPStatus> {
            
            let userID = try req.requireAuthenticated(User.self).requireID() // 1
 
            return try req.parameters.next(Ad.self).flatMap(to: HTTPStatus.self) { ad in // 2
         
                let adID = try ad.requireID() // 3
                return Heart.query(on: req).filter(\Heart.userID == userID).filter(\Heart.adID == adID).first().flatMap(to: HTTPStatus.self) { existingHeart in // 4
                   
                    if let foundHeart = existingHeart { // 5
                        return foundHeart.delete(on: req).transform(to: .ok) // 6
                    } else { // 7
                        return Heart(adID: adID, userID: userID).save(on: req).transform(to: .ok) // 10
                    }
                }
            }
        }
    

    /// # Delete by ID
    /// - parameters:
    ///    - req: Request
    ///    - returns: Future : HTTPStatus
    /// - throws: Abort Error
    ///
    /// 1. Method to DELETE to /api/ads/<ID>/delete that returns Future<HTTPStatus>
    /// 2. Get the authenticated user from the request.
    /// 3. Extract the UUID from the request’s parameters.
    /// 4. Make a query to the Ad table and filter the results with the adID and get the first one. FlatMap to Future<HTTPStatus>.
    /// 5. Unwrap the result of the query.
    /// 5a. Look up if the auhtenticated user has an admin access OR if the authenticated user is the one who created the ad. If yes execute the closure.
    /// 6. In the do catch block execute the deletion. Call the willSoftDelete method which takes care of deleting the children models of the ad (offers, demands, hearts). Throws abort if errors occur.
    /// 7. If the ad has images -->
    /// 8. Make an aws instance.
    /// 9. Delete each file by calling deleteFile method in the closure.
    /// 10. Map the errors if there are any, print a message and throw abort.
    /// 11. Catch the errors of the do-catch block, print out the message and throw an abort.
    /// 12. Delete the Object using delete(on:). Instead of requiring you to unwrap the returned Future, Fluent allows you to call delete(on:) directly on that Future. This helps tidy up code and reduce nesting. Fluent provides convenience functions for delete, update, create and save.  Transform the result into a 204 No Content response. This tells the client the request has successfully completed but there’s no content to return.
    /// 13. If the authenticated user doesn't have an admin access or if the user doesn't own the ad, throw an abort (forbidden).
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> { // 1
        
        let user = try req.requireAuthenticated(User.self) // 2
        let adID = try req.parameters.next(UUID.self) // 3
        
        return Ad.query(on: req).filter(\Ad.id == adID).first().flatMap(to: HTTPStatus.self) { foundAd in // 4
       
            // 5
            guard let existingAd = foundAd else{throw Abort(.notFound)}
            
            if try user.userType == .admin || existingAd.userID == user.requireID() { // 5a
            
                do { // 6
                    _ = try existingAd.willSoftDelete(on: req, ad: existingAd)
                    
                    // 7
                    if existingAd.images != nil {
                        let aws = AwsController.init(awsConfig: self.awsConfig) // 8
                        _ = try existingAd.images!.map { try aws.deleteFile(req, name: $0) // 9
                            .catchMap({ error in // 10
                                print(error, "Error with deleting images of the ad.")
                                throw Abort(.internalServerError)
                            })
                        }
                    } // 11
                } catch let error {
                    print(error, "Error with the deletion")
                    throw Abort(.internalServerError)
                }
                // 12
                return existingAd.delete(on: req).transform(to: .noContent)
                } else { // 13
                    throw Abort.init(.forbidden)
            }
        }
    }
    
    
    /// # GET AD(s) FROM THE USER
    /// - parameters:
    ///   - req: Request
    ///   - returns: Future : AdOfUserData
    /// - throws: Abort Error
    ///
    /// 1. Declare a new route handler that returns Future<AdOfUserData>
    /// 2. Get the authenticated user from the request. If the instance is not authenticated or if there are other problems functions throws. Get the id of the user.
    /// 3. Make a query to the database table named Ad and return the first model which ad.userID equals to the authenticated user's id.
    /// 4. Unwrap the ad. If it doesn't exist throw an abort. FlatMap the result to Future<AdWithUserData>.
    /// 5. Get the ad’s demands using the computed property.
    /// 6. Get the ad’s offers using the computed property.
    /// 7. Return ad's hearts (children) and unwrap the result.
    /// 8. Get the ad's city.
    /// 9. Call the supplied callback when all four futures have completed and return Future<AdOfUserData>.
    /// 10. Unwrap  date property.
    /// 11. Convert the date to a string (a French date format)
    /// 12. Create AdOfUserData instance and return it.
    
    func getAdsFromUSerHandler(_ req: Request) throws -> Future<AdOfUserData> { // 1
        // 2
        let user = try req.requireAuthenticated(User.self)
        let id = try user.requireID()
        return Ad.query(on: req).filter(\Ad.userID == id).first().unwrap(or: Abort(.notFound)).flatMap(to: AdOfUserData.self) { existingAd in // 3 & 4
            
            
            let demands =  try existingAd.demands.query(on: req).all() // 5
            let offers =  try existingAd.offers.query(on: req).all() // 6
            let hearts = try existingAd.hearts.query(on: req).all() // 7
            let city = existingAd.city.get(on: req) // 8
            
            return map(to: AdOfUserData.self, demands, offers, city, hearts) { demands, offers, city, hearts in // 9
                
                guard let date = existingAd.adCreatedAt else {throw Abort.init(.notFound)} // 10
                let stringDate = date.formatToFrenchDate(date: date) // 11
           
                return AdOfUserData(adID: try existingAd.requireID(), note: existingAd.note, images: existingAd.images, demands: demands, offers: offers, city: city, hearts: hearts.count, createdAt: stringDate) // 12
            }
        }
    }
    
    /**
     # Get Parent (City)
          - parameters:
            - req: Request
         - returns: Future : City
         - throws: Abort Error
        
         1. Define a new route handler, getDepartmentHandler(_:), that returns Future<City>.
         2. Fetch the object specified in the request’s parameters and unwrap the returned future.
         3. Use the computed property to get the child’s parent.
     */
    
    func getCityHandler(_ req: Request) throws -> Future<City> { // 1

        return try req.parameters.next(Ad.self).flatMap(to: City.self) { ad in // 2
            ad.city.get(on: req) // 3
            
        }
    }
    
    /**
     # Get children (Demand)
         - parameters:
                - req: Request
         - returns: Future : [Demand]
         - throws: Abort Error
         1. Define a new route handler, getDemandsHandler(_ :) that return Future<Demand>.
         2. Fetch the object specified in the reques't parameters and unwrap the returned future.
         3. Use the property to query all the children.
     */
    
    func getDemandsHandler(_ req: Request) throws -> Future<[Demand]> { // 1

        return try req.parameters.next(Ad.self).flatMap(to: [Demand].self) { ad in // 2
            
            try ad.demands.query(on: req).all() // 3
        }
    }
    
    
    
    
    /// #  Get children (Offer)
    /// - parameters:
    ///        - req: Request
    /// - returns: Future : [Offer]
    /// - throws: Abort Error
    
     /*
     1. Define a new route handler, getOfferssHandler(_ :) that return Future<[Offer]>.
     2. Fetch the object specified in the reques't parameters and unwrap the returned future.
     3. Use the property to query all the children.
     */
    
    func getOffersHandler(_ req: Request) throws -> Future<[Offer]> { // 1

        return try req.parameters.next(Ad.self).flatMap(to: [Offer].self) { ad in // 2
            try ad.offers.query(on: req).all() // 3
        }
    }
    

    
    // MARK: - GET ALL THE ADS OF THE PERIMETER
    
    /**
     # GET ADS OF THE PERIMETER
     
         - parameters:
            - req: Request
         - returns: Future : AdsOfPerimeterData
         - throws: Abort Error
        
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

            return try department.departmentsInsideOfPerimeter.query(on: req).all().flatMap(to: AdsOfPerimeterData.self) { perimeter in // 3.

                var departments = perimeter // 4.
                departments.insert(department, at: 0) // 5.
                let cities = try departments.map{try $0.cities.query(on: req).all()} // 6.
                let flattenCities = cities.flatten(on: req) // 7.

                return flattenCities.flatMap(to: AdsOfPerimeterData.self) { arrayOfArraysOfCities in // 8.

                    let arrayOfCities = arrayOfArraysOfCities.flatMap {$0} // 9.
                    let ads = try arrayOfCities.map{try $0.adsOfCity.query(on: req).range(..<50).all() } // 10.
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
    
    /**
     # GET ALL THE ADS WITH ITS DATA
     
        - parameters:
            - req: Request
        - throws: Abort
        - Returns: Future Array of AdWithUser models
    
         1. Declare a new route handler that returns Future<AdData>
         2. Make a query to the Ad table and join the User table in to the query by using the common property, userID. Sort the models in from the newest to the oldest and decode the User model also. Query all the objects. This returns a tuple.
         3. Map the tuple to create AdWithUser objects.
         4. Convert the user to public.
         5. Get the ad’s demands using the computed property.
         6. Get the ad’s offers using the computed property.
         7. Return ad's hearts (children) and unwrap the result.
         8. Get the ad's city.
         9. Call the supplied callback when all four futures have completed.
         10. Get the city's department using the get function.
         11. Unwrap date and convert it to a string (a french date form).
         12. Create the model with data we fetched from the database.
         13. Flatten the result of the map and return the result.
    */
    
    func adWithUserHandler(_ req: Request) throws -> Future<[AdWithUser]> { // 1.

        return Ad.query(on: req).join(\User.id, to: \Ad.userID).sort(\Ad.adCreatedAt, .ascending).alsoDecode(User.self).all().flatMap(to: [AdWithUser].self) { adUserPairs in // 2.
            
           let data = try adUserPairs.map { ad, user -> Future<AdWithUser> in // 3
            
                let publicUser = user.convertToPublic() // 4
                let demands = try ad.demands.query(on: req).all() // 5
                let offers = try ad.offers.query(on: req).all() // 6
                let hearts = try ad.hearts.query(on: req).all() // 7
                let city = ad.city.get(on: req) // 8
                
                return flatMap(to: AdWithUser.self, demands, offers, city, hearts) { demands, offers, city, hearts in // 9
                    
                    return city.department.get(on: req).map(to: AdWithUser.self) { department in // 10
                        // 11
                        guard let date = ad.adCreatedAt else {throw Abort.init(.notFound)}
                        let stringDate = date.formatToFrenchDate(date: date)
                        
                        
                        return AdWithUser(ad: ad, user: publicUser, demands: demands, offers: offers, city: city, department: department, hearts: hearts.count, createdAt: stringDate) // 12
                        
                    }
                }
            }
            
            return data.flatten(on: req) // 13
            
        }
    }
    
    
    /**
    # GET ONE AD
     
        - parameters:
            - req: Request
        - throws: Abort
        - Returns: Future  AdData
    
        1. Declare a new route handler that returns Future<AdData>
        2. Extract the ad from the request's parameters and unwrap the result.
        3. Get the ad’s demands using the computed property.
        4. Get the ad’s offers using the computed property.
        5. Return ad's hearts (children) and unwrap the result.
        6. Get the ad's city.
        7. Call the supplied callback when all four futures have completed and return Future<AdData>.
        8. Get the city's department using the get function and return Future<AdData>.
        9. Unwrap date.
        10. Convert the date to a string (a date in French)
        11. Create AdData with data we fetched from the database.
    */
    
    func adHandler(_ req: Request) throws -> Future<AdData> { // 1.

        return try req.parameters.next(Ad.self).flatMap(to: AdData.self) { ad in // 2.
            
            let demands = try ad.demands.query(on: req).all() // 3.
            let offers = try ad.offers.query(on: req).all() // 4.
            let hearts = try ad.hearts.query(on: req).all() // 5.
            let city = ad.city.get(on: req) // 6.
            return flatMap(to: AdData.self, demands, offers, city, hearts) { demands, offers, city, hearts in // 7.
                
                return city.department.get(on: req).map(to: AdData.self) { department in // 8.
              
                    guard let date = ad.adCreatedAt else {throw Abort.init(.notFound)} // 9.
                    let stringDate = date.formatToFrenchDate(date: date) // 10.
                    
                    return AdData(note: ad.note, adID: try ad.requireID(), images: ad.images, demands: demands, offers: offers, department: department, city: city, hearts: hearts.count, createdAt: stringDate, userID: ad.userID) // 11.
                }
            }
        }
    }
 
    /**
     # Route handler to update the ad. Function returns Future<HTTPStatus> and throws if errors occur.
        - parameters:
            - req: Request
        - throws: Abort
        - Returns: Future  AdData
    
        1. Route handler to update the ad. Function returns Future<HTTPStatus> and throws if errors occur.
        2. Get the authenticated user.
        3. Extract the adID from the request's parameter.
        4. Use flatMap(to:,:,:) extract futures and return Future<HTTPStatus>
        5. Try to query the ads of the user, filter the results with adID and return the first one.
        6. Decode the content of the request to Future<AdInfoPostData>
        7. Found ad is the result of the query: newData is the decoded content.
        8. Unwrap the found ad.
        9. Update the values of the ad with the new data.
        10. Update the city by calling a method.
        11.  Save the updated ad and transform the future to Future<[Demand]>. Use flatMap(to:) on save(on:) but returns all the ad's demands. Note the chaining of futurs instead of nesting them.
        12. Create an array of object names from the Models in the database.
        13. Create a set for the models in the databse and anpther for the models supplied with the request.
        14. Calculate the models to add to the ad and the models to remove.
        15. Create an array of model operation results.
        16. Loop through all the models to add and call Class method to create a new model. Add each result to the results array.
        17. Loop through all the model names to remove.
        18. Get the Model object from the name of the model to remove.
        19. If the Model object exists, delete model.
        20. Return ad's Offers.
        21. Flatten all the future model results and transform the result to the response.
     */
    func updateAdHandler(_ req: Request) throws -> Future<Response> {
        
        let user = try req.requireAuthenticated(User.self) // 2
        let adID = try req.parameters.next(UUID.self) // 3
        
        return try flatMap( // 4
        to: Response.self,
        try user.adsOfUser.query(on: req).filter(\Ad.id == adID).first(), // 5
        req.content.decode(AdInfoPostData.self) // 6
        ) { foundAd, newData in // 7
        
            guard let existingAd = foundAd else {throw Abort(.notFound)} // 8
            
            existingAd.note = newData.note // 9
             _ = try City.updateCity(req, data: EditCityData(newName: newData.city, cityID: newData.cityID, departmentID: newData.departmentID)) // 10
            // 11
            return existingAd.save(on: req).flatMap(to: [Demand].self) { _ in
                try existingAd.demands.query(on: req).all()
                }.flatMap(to: Response.self) { existingDemands in
                    // 12
                    let existingStringArray = existingDemands.map {
                        $0.demand
                    }
                    // 13
                    let existingSet = Set<String>(existingStringArray)
                    let newSet = Set<String>(newData.demands)
                    // 14
                    let demandsToAdd = newSet.subtracting(existingSet)
                    let demandsToRemove = existingSet.subtracting(newSet)
                    // 15
                    var demandResults: [Future<Void>] = []
                    // 16
                    for newDemand in demandsToAdd where newDemand.count > 0 {
                        demandResults.append(try Demand.addDemand(newDemand, to: existingAd, on: req))
                        
                    }
                    // 17
                    for demandNameToRemove in demandsToRemove {
                        // 18
                        let demandToRemove = existingDemands.first {
                            $0.demand == demandNameToRemove
                        }
                        // 19
                        if let demand = demandToRemove {
                          _ = demand.delete(on: req)
                        }
                    }
                    // 20
                    return try existingAd.offers.query(on: req).all().flatMap(to: Response.self) { existingOffers in
                        // 12
                        let existingStringArray = existingOffers.map {
                            $0.offer
                        }
                        // 13
                        let existingSet = Set<String>(existingStringArray)
                        let newSet = Set<String>(newData.offers)
                        // 14
                        let offersToAdd = newSet.subtracting(existingSet)
                        let offersToRemove = existingSet.subtracting(newSet)
                        // 15
                        var offerResults: [Future<Void>] = []
                        // 16
                        for newOffer in offersToAdd where newOffer.count > 0 {
                            offerResults.append(try Offer.addOffer(newOffer, to: existingAd, on: req))
                        }
                        // 17
                        for offerNameToRemove in offersToRemove {
                            // 18
                            let offerToRemove = existingOffers.first {
                                $0.offer == offerNameToRemove
                            }
                            // 19
                            if let offer = offerToRemove {
                                _ = offer.delete(on: req)
                            }
                        }
                        // 21
                        return demandResults.flatten(on: req).transform(to: req.response())
                    }
            }
        }
    }
}
