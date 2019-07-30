//
//  UserController.swift
//  App
//
//  Created by Sötnos on 03/07/2019.
//


import Vapor
import Crypto
import JWT
import Fluent

// Define different route handlers. To access routes you must register handlers with the router. A simple way to do this is to call the functions inside your controller froum routes.swift


struct UserController : RouteCollection {
    
    // MARK : - Route Registeration
    
     func boot(router: Router) throws {
        
        
        /// Grouped Routes (/api/users)
        let userRoute = router.grouped("api/users")

        /// 1. Create a protected route group using HTTP basic authentication. This doesn't use GuardAuthentication since requireAuthenticated(_:) throws the correct error if a user           isn't authenticated. Create a basicAuthGroup for them.
        /// 2. Create a TokenAuthenticationMiddleware for User. This uses BearerAuthenticationMiddleware to extract the bearer token out of the request. The middleware then convert            s this token into a logged in user. Create a
        /// 3. Create a GuardAuthMiddleware. Error to throw if the type is not authed.
        /// 4. Create a route group using tokenAuthMiddleware and guardAuthMiddleware to protect the route for creating a user with token authentication.

        let basicAuthMiddleware = User.basicAuthMiddleware(using: BCryptDigest()) // 1
        let basicAuthGroup = userRoute.grouped(basicAuthMiddleware)
        let tokenAuthMiddleware = User.tokenAuthMiddleware() // 2
        let guardAuthMiddleware = User.guardAuthMiddleware() // 3
        let tokenAuthGroup = userRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware) // 4
        
        /* Route group type + Request Type (POST, GET, PUT, DELETE) (+ Path component + Method)
         1. Protected Get Request : Retrieve all users
         2. Protected Get Request : Retrieve a user using parameter (by ID)
         3. Post Request : Post Login Credentials at "login" to authorize and create a token for user.
         4. Post Request : Post User data to to create a user
         5. Delete Request : Delete a token of the user.
         6. Delete Request : Delete all tokens of the user.
        */
        
        tokenAuthGroup.get(use: getAllHandler) // 1
        tokenAuthGroup.get(User.parameter, use: getHandler) // 2
        userRoute.post(LoginPostData.self, at: "login", use: loginPostHandler) // 3
        basicAuthGroup.post(User.self, use: createHandler) // 4
        tokenAuthGroup.delete("logout", use: logoutHandler) // 5
        tokenAuthGroup.delete("logout", "all", use: destroyAllTokensHandler) // 6
    }
    
    // MARK: - Route Handlers

/// Create User
///  1. Function has a User as a parameter which is a decoded from the request and returns the public user.
///  2. This hashes the user's password before saving it in the database
///  3. This uses extension for Future<User>. As a result you don't need to unwrap the result of the save yourself.
    
    func createHandler(_ req: Request, user: User) throws -> Future<User.Public> { //1
        user.password = try BCrypt.hash(user.password) // 2
        return user.save(on: req).convertToPublic() // 3
    }
    
    
/// Retrieve all users
/// 1. Function retrieves all users and returns public versions of them.
/// 2. Decodes the data returned from the query into User.Public.
 
    
    func getAllHandler(_ req: Request) throws -> Future<[User.Public]> { // 1
        return User.query(on: req).decode(data: User.Public.self).all() // 2
    }
    
    
/// Retrieve one user by ID
/// 1. Function retrieves a user and returns public version of it.
/// 2. Extract the object(User.self) from the request using parameters. This computed property performs all the work necessary to get the object(User) from the database. Then           convert the User to Public by using the extension for Future<User>.
 
    
    func getHandler(_ req: Request) throws -> Future<User.Public> { // 1
        
        return try req.parameters.next(User.self).convertToPublic() // 2
    }
    
    
/// Login Post Handler - Function Authenticates an user and creates a Token
///  1. The function has two parameters: LoginPostData and request. Returns Future<Token>
///  2. Decodes userdata. If error: fatalErrow with a message.
///  3. Authenticates the user: if the password and the email are correct closure returns the user fetched from the database and maps it Future<String>.
///  4. Unwrap the user. If it's a nil the user has not been authorized and function throws an abort.
///  5. Generates a token for the user.
///  6. Returns and saves the tokne.
 
    func loginPostHandler(_ req: Request, userData: LoginPostData) throws -> Future<Token> { // 1.
        guard let username = userData.username.fromBase64(), let password = userData.password.fromBase64() else {fatalError("Corrupted credentials")} // 2.
        return User.authenticate(username: username, password: password, using: BCryptDigest(), on: req).flatMap(to: Token.self) { user in // 3.
            guard let user = user else {throw Abort(.unauthorized) } // 4.
            let token = try Token.generate(for: user) // 5.
            return token.save(on: req) // 6.
        }
    }
    
    
    /// Make a delete request to delete all the tokens of the user: It's possible to be loged in with only one device!
    ///  1. Return the authenticated user and query all the auth tokens.
    ///  2. Delete tokens.
    ///  3. Transform to noContent HTTPStatus.
    
    func destroyAllTokensHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.requireAuthenticated(User.self).authTokens.query(on: req) // 1
            .delete() // 2
            .transform(to: .noContent)
    }
    
    /// Make a delete request to delete a token of the user.
    ///  1. Get a bearer token from the request's HTTPHeaders. If the token is nil throw an Abort. (It should not be.)
    ///  2. Query all the tokens and filter them based on the token string. Map the result to Future<HTTPStatus>.
    ///  3. In the completion handler unwrap the found token.
    ///  4. Delete the existing token and transform it to noContent -HTTPStatus.
    
    func logoutHandler(_ req: Request) throws -> Future<HTTPStatus> {
        
        guard let token = req.http.headers.bearerAuthorization?.token else {throw Abort(.noContent)} // 1
        return Token.query(on: req).filter(\.token == token).first().flatMap(to: HTTPStatus.self) { foundToken in // 2
          
            guard let existingToken = foundToken else{ throw Abort(.noContent)} // 3
            return existingToken.delete(on: req).transform(to: .noContent) // 4
        }
    }
    
    
    
    
}


/// Datatype which we use to authenticate the user
/// - username
/// - password

struct LoginPostData : Content {
    let username : String
    let password : String
}
