import Vapor
import Fluent

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    
    // Basic "It works" example
    
    /*
     Register Controllers
     1. Create a new controller object
     2. Register the new type with the router to ensure the controller's router get registered
     */
    
    let adController = AdController()  // 1
    try router.register(collection: adController) //2
    
    let departmentConroller = DepartmentController() // 1
    try router.register(collection: departmentConroller) // 2
    
    let countryController = CountryController() // 1
    try router.register(collection: countryController) // 2
    
    let cityController = CityController() // 1
    try router.register(collection: cityController) // 2
    
    let contactController = ContactController() // 1
    try router.register(collection: contactController) // 2
    
    let heartController = HeartController() // 1
    try router.register(collection: heartController) // 2
    
    let demandController = DemandController() // 1
    try router.register(collection: demandController) // 2
    
    let offerController = OfferController() // 1
    try router.register(collection: offerController) // 2
    
    let userController = UserController() // 1
    try router.register(collection: userController) // 2
    
}
