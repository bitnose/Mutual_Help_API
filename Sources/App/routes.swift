import Vapor
import Fluent

/// Register your application's routes here.
public func routes(_ router: Router, awsConfig: AwsConfig) throws {
    
    // Basic "It works" example
    
    /*
     Register Controllers
     1. Create a new controller object
     2. Register the new type with the router to ensure the controller's router get registered
     */
    
    let adController = AdController(awsConfig: awsConfig)  // 1
    try router.register(collection: adController) //2
    
    let departmentConroller = DepartmentController() // 1
    try router.register(collection: departmentConroller) // 2
    
    let countryController = CountryController() // 1
    try router.register(collection: countryController) // 2
    
    let cityController = CityController() // 1
    try router.register(collection: cityController) // 2
    
    let demandController = DemandController() // 1
    try router.register(collection: demandController) // 2
    
    let offerController = OfferController() // 1
    try router.register(collection: offerController) // 2
    
    let userController = UserController(awsConfig: awsConfig) // 1
    try router.register(collection: userController) // 2
    
    let awsController = AwsController(awsConfig: awsConfig)
    try awsController.boot(router: router)

    
}
