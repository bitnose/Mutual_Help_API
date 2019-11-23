//
//  UserController.swift
//  App
//
//  Created by Sötnos on 03/07/2019.
//


import Vapor
import Crypto
import Fluent
import Authentication
//
import SwiftSMTP

// Define different route handlers. To access routes you must register handlers with the router. A simple way to do this is to call the functions inside your controller from routes.swift
struct UserController : RouteCollection {
    // MARK: - Properties
    private let awsConfig: AwsConfig
    
    // MARK: - Inits
    init(awsConfig: AwsConfig) {
        self.awsConfig = awsConfig
    }
     // MARK: - Route Registration
     func boot(router: Router) throws {
        
        /// Grouped Routes (/api/users)
        let userRoute = router.grouped("users")

        /// # Route groups
        /// 2. Create a TokenAuthenticationMiddleware for User. This uses BearerAuthenticationMiddleware to extract the bearer token out of the request. The middleware then converts this token into a logged in user. Create a
        /// 3. Create a GuardAuthMiddleware. Error to throw if the type is not authenticated.
        /// 4. Create a route group using tokenAuthMiddleware and guardAuthMiddleware to protect the route for creating a user with token authentication.
        /// 5. Create an adminGroup for routes which requires the user have an admin access. (Right now all actions)

        let tokenAuthMiddleware = User.tokenAuthMiddleware() // 2
        let guardAuthMiddleware = User.guardAuthMiddleware() // 3
        let tokenAuthGroup = userRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware) // 4
        let adminGroup = tokenAuthGroup.grouped(AdminMiddleware()) // 5
  //      let standardGroup = tokenAuthGroup.grouped(StandardUserMiddleware())
        
        /* Route group type + Request Type (POST, GET, PUT, DELETE) (+ Path component + Method)
         1. Protected Get Request : Retrieve all users
         2. Protected Get Request : Retrieve a user using parameter (by ID)
         
         
         5. Delete Request : Delete a token of the user.
         6. Delete Request : Delete all tokens of the user.
         7. Get Request :
         8. Put Request : Update the User data (not the password)
         9. Put Request : Update the password of the user
        */
        
        
        // MARK: - OPEN ACCESS
        //
        // 1. Post Request : Post Login Credentials to authorize and create a token for user.
        // 2. Post Request : Post Register data to to create and register a new user
        // 3. Post Request : Post Email to send a password reset email to the user
        userRoute.post(LoginPostData.self, at: "login", use: loginPostHandler) // 1
        userRoute.post(RegisterPostData.self, at: "register", use: registerUserHandler) // 2
        userRoute.post("resetPassword", use: resetPasswordHandler) // 3
        userRoute.post("confirmResetToken", use: confirmResetTokenHandler)
        userRoute.post(ResetPasswordTokenData.self, at: "updatePassword", use: updatePasswordHandler)
        
        // MARK: - STANDARD ACCESS
        //
        // 1. Delete Request : Delete token from the user (logout)
        // 2. Delete Request : Delete all the tokens from the user (logout from all the devices)
        // 3. Get Request : Get the User.Public of the authenticated user
        // 4. Put Request : Update the user data
        // 5. Put Request : Update the password
        // 6. Get Request : Get the contacts of the user
        // 7. Get Request : Get the contact requests of the user
        // 8. Post Request : Send contact request
        // 9. Put Request : Accept contact request
        // 10. Get Request : Get contact data of the ad
        // 11. Delete Request : Decline the contact request
        // 12. Delete Request : Delete user
        tokenAuthGroup.delete("logout", use: logoutHandler) // 1
        tokenAuthGroup.delete("logout", "all", use: destroyAllTokensHandler) // 2
        tokenAuthGroup.get("self", use: getMyProfileHandler) // 3
        tokenAuthGroup.put(UserData.self, at: "edit", use: editUserDataHandler) // 4
        tokenAuthGroup.put(PasswordData.self, at: "change", "password", use: changePasswordHandler) // 5
        tokenAuthGroup.get("contacts", use: getContactsHandler) // 6
        tokenAuthGroup.get("contacts", "requests", use: getContactRequestsHandler) // 7
        tokenAuthGroup.post(UUID.parameter, "request", "send", use: sendContactRequestHandler) // 8
        tokenAuthGroup.put(UUID.parameter, "contacts", "requests", "accept", use: acceptContactRequestHandler) // 9
        tokenAuthGroup.get(Ad.parameter, "contacts", use: getSingleContactHandler) // 10
        tokenAuthGroup.delete(UUID.parameter, "contacts", "requests", "decline", use: declineContactRequestHandler) // 11
        tokenAuthGroup.delete("delete", "user", User.parameter, use: forceDeleteUserHandler) // 12
        
        // MARK: - ADMIN ACCESS
        //
        // 1. Get Request : Get all the registered users
        // 2. Get Request : Get the access type of the authenticated user.
        adminGroup.get("all", use: getAllHandler) // 1
        adminGroup.get("access", use: getMyProfileHandler) // 2
       
    }
    
    
    /**
     # Delete User Handler
      - parameters:
        - req: Request
     - Returns: Future HTTPStatus
     - Throws: AbortError
     
     1. Extract the user from the request's parameters and return Future HTTPStatus.
     2. Get the authenticated user.
     3. Look up if the user is admin user or if the authenticated user and the user from the parameters are same. If yes, delete user model, it's ad, offers, demands and hearts, and tokens.
     4. Query user's ads from the database.
     5.  In the do catch block delete all the children models and remove the model from the relationships.
     6.  Iterate the adsToRemove trouhgh.
     7. Call willSoftDelete method to delete child models of ad. Catch the errors.
     8. Print out the error and the message and throw abort.
     9. If the ad has images,.
     10. Create an aws instance what we will use to call the mehtod to delete images from the aws bucket.
     11. Call the method to delete images from the aws bucket.
     12. Catch the errors if there are any and print them out. Throw Abort.
     13. Delete ad and transform to void.
     14.  Call willSoftDelete method to delete the child models of the user and detach the user from its relationships.
     15. Delete and return the user and transform to no content.
     16.  Catch the errors and print them out. Throw Abort.
     17. If the user doesn't have the admin access or if the authenticated user is not the same as the user to remove, throw an abort (forbidden).
     */
    func forceDeleteUserHandler(_ req: Request) throws -> Future<HTTPStatus> {
        
        return try req.parameters.next(User.self).flatMap(to: HTTPStatus.self) { userToRemove in // 1
            
            let authenticatedUser = try req.requireAuthenticated(User.self) // 2
            if try authenticatedUser.userType == .admin || authenticatedUser.requireID() == userToRemove.requireID() { // 3

                return try userToRemove.adsOfUser.query(on: req).all().flatMap(to: HTTPStatus.self) { adsToRemove in // 4
                    
                    do { // 5
                        _ = try adsToRemove.map { // 6
                        
                            _ = try $0.willDelete(on: req, ad: $0, force: true).catchMap({ error in // 7
                                print(error, "Error with deleting the child models of the ad.") // 8
                                throw Abort(.internalServerError)
                            })
            
                            if $0.images != nil { // 9
                                let aws = AwsController.init(awsConfig: self.awsConfig) // 10
                                _ = try  $0.images!.map { try aws.deleteFile(req, name: $0) // 11
                                    // 12
                                    .catchMap({ error in
                                    print(error, "Error with deleting images of the ad.")
                                    throw Abort(.internalServerError)
                                    })
                                }
                            }
                        _ = $0.delete(on: req).transform(to: ()) // 13

                        }
                        return try userToRemove.willDelete(on: req, user: userToRemove).flatMap(to: HTTPStatus.self) { _ in // 14
                            return userToRemove.delete(force: true, on: req).transform(to: .noContent) // 15
                            
                                
                        }
                    } catch let error { // 16
                        print(error, "Error with the deletion")
                        throw Abort(.internalServerError)
                    }
                }
            } else { // 17
                print("The user is not allowed to perform the action.")
                throw Abort.init( .forbidden)
            }
        }
    }
    
    
    
    
    /**
     # Get the authenticated user
     
     - Parameters:
            - req: Request
     - Returns: Future Response
     - Throws: AbortError
     
     1. Get the auhtenticated user from the request.
     2. Convert the user to public version.
     3. Asynchronously encodes Self into a Response, setting the supplied status and headers.
     */
    
    func accessTypeHandler(_ req: Request) throws -> Future<Response> {
        
        return try req.requireAuthenticated(User.self)
            .convertToPublic()
            .encode(status: .ok, for: req)
        
    }
    
    
    
    // MARK: - Create a new uses / Register user
    
    /// # Register User
    ///
    /// - Parameters:
    ///     - req: Request
    ///     - data : RegisterPostData
    /// - Throws: Abort
    /// - Returns: Future : Token
    ///
    /// 1. Parameters: Request, User; Throws if errors occur; Returns a Future<Token>.
    /// 2. Hash the password.
    /// 3. Create a new user. User type is standard.
    /// 4. Save the user and map the result to Future<Token>
    /// 5. Generate a token for the user.
    /// 6. Save and return the token.
    func registerUserHandler(_ req: Request, data: RegisterPostData) throws -> Future<Token> { // 1
     
        let hashedPassword = try BCrypt.hash(data.password) // 2
        return User(firstname: data.firstname, lastname: data.lastname, email: data.email, password: hashedPassword, userType: .standard) // 3
            .save(on: req).flatMap(to: Token.self) { savedUser in // 4
            let token = try Token.generate(for: savedUser) // 5
                
            // Send email to the email address
    //        SMTPHelper.init(email: "eegj@eegj.fr").sendMail(name: savedUser.firstname, email: savedUser.email)
                
                
            //    self.sendMail(name: "Anniina", email: "anniina.korkiakangas@gmail.com")
            return token.save(on: req) // 6
                
                
            
        }
    }
    
    
    
    // MARK: - Route Handlers

    /// # Edit User
    ///
    /// - Parameters:
    ///     - req: Request
    ///     - data : UserData
    /// - Throws: Abort
    /// - Returns: Future : Response
    ///
    ///  1. Function has a UserData as a parameter which is a decoded from the request and returns a response.
    ///  2. Get the authenticated user from the request.
    ///  3. Update the user's data with the new data.
    ///  4. Save the updated user and transform to response.
    
    func editUserDataHandler(_ req: Request, data: UserData) throws -> Future<Response> { // 1
        let user = try req.requireAuthenticated(User.self) // 2
        // 3
        user.firstname = data.firstname
        user.lastname = data.lastname
        user.email = data.email
        return try user.save(on: req).toResponse(on: req, as: .ok) // 4
    }
    
    
    
    
    /// # Get all users
    ///
    /// - Parameters:
    ///     - req: Request
    /// - Throws: Abort
    /// - Returns: Future : [User.Public]
    ///
    /// 1. Function retrieves all users and returns public versions of them.
    /// 2. Decodes the data returned from the query into User.Public.
 
    func getAllHandler(_ req: Request) throws -> Future<[User.Public]> { // 1
      
        return User.query(on: req).decode(data: User.Public.self).all() // 2
    }
    
    
    /// # Retrieve one user by ID
    ///
    /// - Parameters:
    ///     - req: Request
    /// - Throws: Abort
    /// - Returns: Future : User.Public
    ///
    /// 1. Function retrieves a user and returns public version of it.
    /// 2. Extract the object(User.self) from the request using parameters. This computed property performs all the work necessary to get the object(User) from the database. Then           convert the User to Public by using the extension for Future<User>.
 
    
    func getHandler(_ req: Request) throws -> Future<User.Public> { // 1
        
        return try req.parameters.next(User.self).convertToPublic() // 2
    }
    
    
    /** # Login Post Handler - Function uthenticates an user and creates a Token
     
     - parameters:
        - req: Request
        - userData : LoginPostData
     - throws: AbortError
     - Returns: Future TokenData
     
     1. Decodes user data. If error: fatalErrow with a message.
     2. Authenticates the user: if the password and the email are correct closure returns the user fetched from the database and maps it Future<String>.
     3. Unwrap the user. If it's a nil the user has not been authorized and function throws an abort.
     4. Query user's tokens.
     5. Create a variable for the tokens.
     6. If the count of the tokens are more or equal to 2.
     7. Repeat the closure until the count is smaller than 2.
     8. In the closure: Delete the first element in the array.
     9. Remove the first element from the array.
     10.  Generates a token for the user.
     11. Save the token.
     12. Create a TokenData from the data and return it.
     */
    func loginPostHandler(_ req: Request, userData: LoginPostData) throws -> Future<TokenData> {
        
        guard let username = userData.username.fromBase64(), let password = userData.password.fromBase64() else {fatalError("Corrupted credentials")} // 1
        return User.authenticate(username: username, password: password, using: BCryptDigest(), on: req).flatMap(to: TokenData.self) { user in // 2
            
            guard let user = user else {throw Abort(.unauthorized) } // 3
            
            return try user.authTokens.query(on: req).all().flatMap(to: TokenData.self) { tokens in // 4

                var modieableTokenArray = tokens // 5
                if tokens.count >= 2 { // 6
                    repeat { // 7
                        _ = modieableTokenArray.first?.delete(on: req) // 8
                        modieableTokenArray.removeFirst() // 9
                    } while modieableTokenArray.count > 2 // 7
                }
                
                let token = try Token.generate(for: user) // 10
                return token.save(on: req).map(to: TokenData.self) { savedToken in// 11.
                
                    return TokenData(token: savedToken, usertype: user.userType.rawValue) // 12.
                }
            }
        }
    }
    
    
    
    /// # Change the Password Handler - Route handler changes the user's password
    ///
    /// - parameters:
    ///   - req: Request
    ///   - passwordData : PasswordData
    /// - throws: AbortError
    /// - Returns: Future Response
    ///
    /// 1. The function has two parameters: PasswordData and request. Returns Future<Response>
    /// 2. Decode the password data. If error throw an error.
    /// 3. Get the authenticated user from the request.
    /// 4. Try to verify the old password (input) with the hashed password of the user in the database. If the method returns true, continue executing the code.
    /// 5. Hash the new password.
    /// 6. Update the password of the user with the new hashed password.
    /// 7. Return the saved user and transform the future to the Future<Response>.
    /// 8. If the passwords doesn't match with each other throw an abort.
    func changePasswordHandler(_ req: Request, passwordData: PasswordData) throws -> Future<Response> { // 1
        
        guard let oldPassword = passwordData.oldPassword.fromBase64(), let newPassword = passwordData.newPassword.fromBase64() else {fatalError("Corrupted data")} // 2
        
        let user = try req.requireAuthenticated(User.self) // 3

        if try BCrypt.verify(oldPassword, created: user.password) == true { // 4
            
            let hashedPassword = try BCrypt.hash(newPassword) // 5
            user.password = hashedPassword // 6
            return try user.save(on: req).toResponse(on: req, as: .accepted) // 7
        } else { // 8
            throw Abort.init(.methodNotAllowed)
        }
    }
    
    
    /// # Make a delete request to delete all the tokens of the user:
    ///
    /// - parameters:
    ///       - req: Request
    /// - throws: AbortError
    /// - Returns: Future HTTPStatus
    ///
    ///  1. Return the authenticated user and query all the auth tokens.
    ///  2. Delete tokens.
    ///  3. Transform to noContent HTTPStatus.
    
    func destroyAllTokensHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.requireAuthenticated(User.self).authTokens.query(on: req) // 1
            .delete() // 2
            .transform(to: .noContent) // 3
    }
    
    /// # Make a delete request to delete a token of the user.
    ///
    /// - parameters:
    ///      - req: Request
    /// - throws: AbortError
    /// - Returns: Future HTTPStatus
    ///
    ///  1. Get a bearer token from the request's HTTPHeaders. If the token is nil throw an Abort. (It should not be.)
    ///  2. Query all the tokens and filter them based on the token string. Map the result to Future HTTPStatus
    ///  3. In the completion handler unwrap the found token.
    ///  4. Delete the existing token and transform it to noContent -HTTPStatus.
    func logoutHandler(_ req: Request) throws -> Future<HTTPStatus> {
        
        guard let token = req.http.headers.bearerAuthorization?.token else {throw Abort(.noContent)} // 1
        return Token.query(on: req).filter(\.token == token).first().flatMap(to: HTTPStatus.self) { foundToken in // 2
          
            guard let existingToken = foundToken else{ throw Abort(.noContent)} // 3
            return existingToken.delete(on: req).transform(to: .noContent) // 4
        }
    }
    
    /// # Get the public profile of the user who is logged in
    /// 1. Get the authenticated user from the request.
    /// 2. Then convert the User to Public by using the extension for Future User
    
    
    func getMyProfileHandler(_ req: Request) throws -> Future<Response> { // 1
        
        return try req.requireAuthenticated(User.self).convertToPublic().encode(for: req) // 2
    }
    
    // MARK: - CONTACT HANDLERS
    
  /**
     # Get the public profiles of the user who are your friends(contacts)
     - Parameters:
        - req : Request
     - Returns: Future [ContactInfoData]
     - Throws: AbortError
     
     1. Get the authtenticated user from the request.
     2. Make a query to user's friendOf and filter them using  areContacts property == true. Return Future [User.Public].
     3. Convert the user to public.
     4. Make a query to user's myFriends and filter them using  areContacts property == true. Return Future [User.Public].
     5. Convert the user to public.
     6. Combine the two arrays.
     7.  Return the array.
     */
    func getContactsHandler(_ req: Request) throws -> Future<[ContactInfoData]> {

        let user = try req.requireAuthenticated(User.self) // 1
        
        return try user.friendOf.query(on: req).filter(\UserUserPivot.areContacs == true).all().flatMap(to: [ContactInfoData].self) { contacts in // 2

         //   let convertedContacts = contacts.map {$0.convertToPublic()} // 3
            
            return try user.myFriends.query(on: req).filter(\UserUserPivot.areContacs == true).all().flatMap(to: [ContactInfoData].self) { contacts2 in // 4

           //     let convertedUsers = contacts.map {$0.convertToPublic(); } // 5
                let combinedArray = contacts + contacts2 // 6
              
                let data = try combinedArray.map { user -> Future<ContactInfoData> in
                    
                    let publicUser = user.convertToPublic()
                    
                    return try user.adsOfUser.query(on: req).all().map { ads -> ContactInfoData in
                        
                        return ContactInfoData(contact: publicUser, ads: ads)
                    }
                }
               return data.flatten(on: req)
            }
        }
    }

    
    /**
    # Get the contact requests which are not accepted
     
    - Parameters:
        - req : Request
    - Returns: Future [ContactRequestFromData]
    - Throws: AbortError
     
    1. Get the authenticated user from the request.
    2. Make a query to users friends and filter with the UserUserPivot.areContacts==false -property. Map the Future results to Future [User.Public]
    3. Create a ContactRequestFromData objects by iterating the array through.
    */
    func getContactRequestsHandler(_ req: Request) throws -> Future<[ContactRequestFromData]> { // 1
        
        let user = try req.requireAuthenticated(User.self) // 1
        return try user.friendOf.query(on: req).filter(\UserUserPivot.areContacs == false).all().map(to: [ContactRequestFromData].self) { contacts in // 2
            
            return try contacts.map {ContactRequestFromData(userID: try $0.requireID(), firstname: $0.firstname)} // 3
        }
    }

    
    /** Send a contact request handler
     
     - Parameters:
        - req : Request
     - Returns: Future Response
     - Throws: AbortError
     
     1. Get the auhtenticated user from the request.
     2. Extract the ad id from the request's parameters.
     3. Make a query to the Ad table and join to the query User Table to get also the user data of the ad. Filter results with the ad id to fetch the ad with the id and return the first match.
     4. Unwrap the querypair.
     5. Create a pivot.
     6. Return the saved pivot and transform a future to a response.
 */
    func sendContactRequestHandler(_ req: Request) throws -> Future<Response> {
        // The one who sends the request
        let user = try req.requireAuthenticated(User.self) // 1
        let id = try req.parameters.next(UUID.self) // 2
        
        return Ad.query(on: req).join(\User.id, to: \Ad.userID).filter(\Ad.id == id).alsoDecode(User.self).first().flatMap(to: Response.self) { adUserPair in // 3
          
            guard let existingPair = adUserPair else{print("Ad with that user doesn't exist");throw Abort(.notFound)} // 4
            let pivot = try UserUserPivot(user, existingPair.1) // 5
            return try pivot.save(on: req).toResponse(on: req, as: .created) // 6
        }
    }
    
    /**
     # Handler to accept to the contact request.
     
    - Parameters:
        - req: Request
    - Returns: Future Response
    - Throws: AbortError
     
    1. Get the authenticated user from the request.
    2. Make a query to the user's pivots with the contactID.
    3. Ensure that the result of the query is not nil
    4. Update the model.
    5. Save and transform to a response.
    */
    func acceptContactRequestHandler(_ req: Request) throws -> Future<Response> {
        
        let user = try req.requireAuthenticated(User.self) // 1
        let id = try req.parameters.next(UUID.self)
        return try user.friendOf.pivots(on: req).filter(\UserUserPivot.firstUserID == id).first().flatMap(to: Response.self) { foundPivot in // 2
            guard let existingPivot = foundPivot else {throw Abort(.notFound)} // 3
            existingPivot.areContacs = true // 4
            return try existingPivot.save(on: req).toResponse(on: req, as: .accepted) // 5
        }
    }
    
    /**
     # Handler to decline the contact request ie. delete the pivot model
     
    - Parameters:
        - req: Request
    - Returns: Future HTTPStatus
    - Throws: AbortError
     
    1. Get the authenticated user from the request.
    2. Extract the ID from the request's parameters.
    3. Make a query to the user's pivots with the ID and get the first result.
    4. Ensure that the result of the query is not nil
    5. Delete the model and transform to no content.
    */
    func declineContactRequestHandler(_ req: Request) throws -> Future<HTTPStatus> {
        
        let user = try req.requireAuthenticated(User.self) // 1
        let id = try req.parameters.next(UUID.self) // 2
        return try user.friendOf.pivots(on: req).filter(\UserUserPivot.firstUserID == id).first().flatMap(to: HTTPStatus.self) { foundPivot in // 3
            guard let existingPivot = foundPivot else {throw Abort(.notFound)} // 3

            return existingPivot.delete(on: req).transform(to: .noContent)
        }
    }

    /**
     # GET THE CONTACT DATA OF THE AD
     - Parameters:
          - req: Request
      - Returns: Future ContactData
      - Throws: AbortError
     1. Get the authenticated user from the request.
     2. Get the ad ID from the request's parameters.
     3. Ad's userID
     A. Look if the
     4. Get a pivot model using a computed property friendOf to return UserUserPivot model where the other userID is equal to the firstUserID and get the first one. FlatMap to Future : ContactData.self.  This means that the firstUserID initiaited the request. ie the other asked.
     5. Look up if the foundPivot is not nil ie if pivot model was found.
     6. If was found: Make a query to the user table to get data of the user.
        7. Ensure that the user with that ID exists.
        8. If areContacs equals to true -->  Situation when the other user initaited the request and the authenticated user has accepted the request.
            9. Return ContactData with the values. ( TRUE+TRUE)
        10. If areContacts equals not true ie equals to false -->  Situation when the other user initaited the request but the authenticated user hasn't responded to the request.
            11.  Return ContactData with the values. (TRUE+TRUE)
     12. If the pivot model wasn't found ie pivot is nil.
     13. Get a pivot model using a computed property myFriends to return UserUserPivot model where the other userID is equal to the secondUserID and get the first one. FlatMap to Future : ContactData.self.  This means that the seconUserID initiaited the contact request. ie the other asked.
     14.  Make a query to the user table to get data of the user.
        15. Unwrap the user model.
        16. If the pivot model was found ie pivot model is not nil.
            17. If areContacs equals to true -->  Situation when the authenticated user initaited the request and the other user has accepted the request ie the users are contacts.
                18. Return ContactData with the values. (TRUE+TRUE)
            19. In the other cases ie areContacs equals to false -->  Situation when the authenticated user initaited the request but the other user hasn't responded to  the request.
                20. Return ContactData with the values. (TRUE + FALSE )
        21.  If the pivot model wasn't found ie pivot model is nil.  It means that there are no pivot models with these user IDs.
            22. If the authenticated user and the user of the ad are not same (doens't have the same ID) return --> Situation when the contacts request is not initiated at all and there are
                23. Return ContactData. (FALSE + FALSE )
            24. Otherwise this means that the authenticated user owns the ad so it's not possible to initiate the request -->  Contact data will be shown for the user.
                25. Return ContactData (TRUE+TRUE)
     */
    
    func getSingleContactHandler(_ req: Request) throws -> Future<ContactData> {
        
        let user = try req.requireAuthenticated(User.self) // 1
        return try req.parameters.next(Ad.self).flatMap(to: ContactData.self) { ad in // 2
        let userID = ad.userID // 3
       
            if try userID == user.requireID() {
                // call method which return the data 
            }
            return try user.friendOf.pivots(on: req).filter(\UserUserPivot.firstUserID == userID).first().flatMap(to: ContactData.self) { foundPivot in // 4
                
                if foundPivot != nil { // 5
             
                    return User.query(on: req).filter(\User.id == userID).first().map(to: ContactData.self) { foundUser in // 6
                        guard let existingUser = foundUser else {throw Abort(.internalServerError)} // 7

                        if foundPivot?.areContacs == true { // 8
                            //  youAccepted = true // Means you have accepted the request : TRUE + TRUE case -> Return the user
                            return ContactData(contactID: userID, firstname: existingUser.firstname, lastname: existingUser.lastname, email: existingUser.email, youAccepted: true, otherAccepted: true) // 9
                   
                        } else { // 10
                            //  youAccepted = false // Means you haven't accepted the request : TRUE + FALSE case -> User must answer
                            return ContactData(contactID: userID, firstname: existingUser.firstname, lastname: nil, email: nil, youAccepted: false, otherAccepted: true) // 11
                        }
                    }
                } else { // 12
                 //   otherAccepted = false
                   // you asked
                    return try user.myFriends.pivots(on: req).filter(\UserUserPivot.secondUserID == userID).first().flatMap(to: ContactData.self) { foundFriends in // 13
                        
                        return User.query(on: req).filter(\User.id == userID).first().map(to: ContactData.self) { foundUser in // 14
                            
                            guard let existingUser = foundUser else {throw Abort(.internalServerError)} // 15
                                                      
                            if foundFriends != nil { // 16
                                     // youaccepted = true
                                if foundFriends?.areContacs == true { // 17
                                    return ContactData(contactID: userID, firstname: existingUser.firstname, lastname: existingUser.lastname, email: existingUser.email, youAccepted: true, otherAccepted: true) // 18
                                } else { // 19
                                    // otheraccepted = false
                                    return ContactData(contactID: userID, firstname: existingUser.firstname, lastname: existingUser.lastname, email: existingUser.email, youAccepted: true, otherAccepted: false) // 20
                                }
                            } else { // 21
                                if try user.requireID() != userID { // 22
                                    return ContactData(contactID: userID, firstname: existingUser.firstname, lastname: nil, email: nil, youAccepted: false, otherAccepted: false) // 23
                                } else { // 24
                                    return ContactData(contactID: userID, firstname: user.firstname, lastname: user.lastname, email: user.email, youAccepted: true, otherAccepted: true) // 25
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    // MARK: - Reset Password
/*    
//
    // Confirmation email
    func sendMail(name: String, email: String) {
        let smtp = SMTP (
            hostname: "mail.eegj.fr",     // SMTP server address
            email: "eegj@eegj.fr",        // username to login
            password: "akjNCNAJKmad23",            // password to login
            port: 587,
            tlsMode: .requireSTARTTLS,
            tlsConfiguration: nil
        )

        // What are in the message, and emails, etc
        let EEGJ = Mail.User(name: "Little Me - Thyself", email: "anniina.korkiakangas@gmail.com")
        let name = Mail.User(name: name, email: email)
*/
    /**
     # Route Handler to reset password / to send an email to the user
     - parameters:
        - req: Request
     - throws: Abort Error
     - returns: Future Response
     
     1. Decode the email address from the request's content.
     2. Ensure there’s a user associated with the email address. Otherwise throw abort.
     3. Generate a token string using CryptoRandom.
     4. Create a ResetPasswordToken object with the token string and the user’s ID
     5. Save the token in the database and unwrap the returned future.
     6. Call sendResetPassword function.
     7. Return a response.

     */
    
    func resetPasswordHandler(_ req: Request) throws -> Future<Response> {
        
        
        return try req.content.decode(String.self).flatMap(to: Response.self) { email in
        
            return User.query(on: req).filter(\.email == email).first().unwrap(or: Abort(.notFound)).flatMap(to: Response.self) { user in // 2
                
                let resetTokenString = try CryptoRandom().generateData(count: 32).base32EncodedString() // 3
                
                let resetToken = try ResetPasswordToken(token: resetTokenString, userID: user.requireID()) // 4
                    
                return resetToken.save(on: req).map(to: Response.self) { _ in // 5
                    
        
                // 6
               
                    SMTPHelper.init().sendResetPasswordEmail(name: user.firstname, email: user.email, resetTokenString: resetTokenString)
            
                    
                    return req.response() // 7
                }
            }
        }
  
    }
    /**
    # Route Handler to confirm reset password token
    - parameters:
       - req: Request
    - throws: Abort Error
    - returns: Future Bool
    
    1. Decode the string token from the request's content.
    2. Make a query to ResetPasswordToken table to look up if there’s a PasswordToken associated with the resetPasswordString.
    3. If the token was found ie it's not nil.
    4. The date now.
    5. Unwrap the date when the reset token was created.
    6. If nil, delete token and return false.
    7. Set an expiration date for 1h later for the reset token.
    8. Compare the date now to the expiration date.
    9. If not expired, return true.
    10. If expired, delete reset token and return false.
    11. If the foundToken is nil , return false.

    */
    func confirmResetTokenHandler(_ req: Request) throws -> Future<IsValid> {
        
        return try req.content.decode(String.self).flatMap(to: IsValid.self) { resetPasswordString in // 1
            
            return ResetPasswordToken.query(on: req).filter(\.token == resetPasswordString).first().map(to: IsValid.self) { foundToken in // 2
                // 3
                if foundToken != nil {
                    
                    let now = Date() // 4
                    guard let tokenCreated = foundToken!.createdAt else { // 5
                        
                        _  = foundToken!.delete(on: req) // 6
                        return IsValid(isValid: false) // 7
                     }
                    // 7
                    let expirationDate = tokenCreated.addingTimeInterval(60*60) // 1h later
                    print ("now = \(now), expirationDate = \(expirationDate), resetToken date = \(tokenCreated)")
                        // 8
                        if now.compare(expirationDate) == .orderedAscending {
                            return IsValid(isValid: true)
                                   
                        } else { // 10
                            _  = foundToken!.delete(on: req)
                            return IsValid(isValid: false)
                        }
                    // 11
                } else {
                    return IsValid(isValid: false)
                }
            }
        }
    }
    
    
    /**
     # Route Handler to reset password
     - parameters:
        - req: Request
        - data : ResetPasswordData
     - throws: Abort Error
     - returns: Future Response
     
    
     1. Make a query to ResetPasswordToken table to look up if there’s a PasswordToken associated with the resetPasswordString. Join the user to the query.
     2.  Unwrap the pair.
     3. The date now.
     4. Unwrap the date when the reset token was created.  If the date is nil, delete token and return notFound.
     5. Set an expiration date for 1h later for the reset token.
     6. Compare the date now to the expiration date.
     7. If not expired, base 64 encode the password, if error, throw abort.
     8. Hash the password.
     9. Update the password.
     10. Delete reset token from the database.
     11. Query all the auth tokens of the user and delete them.
     12. Save the updated user to the database and return ok.
     13. If the reset token was expired, delete reset token and return notFound.

     */
    
    
    func updatePasswordHandler(_ req: Request, data: ResetPasswordTokenData) throws -> Future<HTTPStatus> {
    
        return ResetPasswordToken.query(on: req).join(\User.id, to: \ResetPasswordToken.userID).filter(\ResetPasswordToken.token == data.token).alsoDecode(User.self).first().flatMap(to: HTTPStatus.self) { resetTokenUserPair in // 1
          
            guard let existingPair = resetTokenUserPair else { print("Ad with that user doesn't exist");throw Abort(.notFound) } // 2
        
            let now = Date() // 3
            guard let tokenCreated = existingPair.0.createdAt else { return existingPair.0.delete(on: req).transform(to: .notFound) } // 4
            let expirationDate = tokenCreated.addingTimeInterval(60*60) // 5
            
            if now.compare(expirationDate) == .orderedAscending { // 6
                
                // ok
                guard let newPassword = data.password.fromBase64() else { print("Corrupted data");throw Abort(.notFound)} // 7

                let hashedPassword = try BCrypt.hash(newPassword) // 8
                existingPair.1.password = hashedPassword // 9
        
                _ = existingPair.0.delete(on: req) // 10
                _ = try existingPair.1.authTokens.query(on: req).delete() // 11
            
                return existingPair.1.save(on: req).transform(to: .ok) // 12
                
            } else {
                
                return existingPair.0.delete(on: req).transform(to: .notFound) // 13
                
            }
        
        }
    
    }
    
    
}


