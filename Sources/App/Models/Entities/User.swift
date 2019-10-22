//
//  User.swift
//  App
//
//  Created by Sötnos on 03/07/2019.
//

import Foundation
import Vapor
import FluentPostgreSQL
import Authentication


/// Class For the User

/// Class contains properties to hold:
/// - ID : Optional id property that stores the ID of the model assigned by the database when it's saved
/// - firstName : A First Name of the user
/// - lastName : A Last Name of the user
/// - email : an email address of the user
/// - password : a password of the user 
/// - usertype : Admin / Standard / Restricted
/// - deletedAt: A property for Fluent to store the date you performed a soft delete on the model

// TODO: - Add username variable and phonenumber variable (optionals)
final class User : Codable {
    
    var id : UUID?
    var firstname : String
    var lastname : String
    var email : String
    var password : String
    var userType : UserType
    var deletedAt: Date?
    
    
/// Init User
    init(firstname: String, lastname: String, email: String, password : String, userType: UserType) {
        self.firstname = firstname
        self.lastname = lastname
        self.email = email
        self.password = password
        self.userType = userType
    }
    
    // Add to new key path that Fluent checks when you call delete(on:). If the key path exists, Fluent sets the current date on the property and saves the updated model. Otherwise, it deletes the model from the database
    static var deletedAtKey : TimestampKey? = \.deletedAt
    
/// Public class of the User : Inner class to represent a public view of User
/// (To protect password hashes you should never return them in responses)
/// - ID : Optional id property that stores the ID of the model assigned by the database when it's saved
/// - First Name
/// - Last Name
/// - Email
    final class Public: Codable {
        var id: UUID?
        var firstname: String
        var lastname: String
        var email : String
        var userType : UserType
        
        init(id: UUID?, firstname: String, lastname: String, email : String, userType : UserType) {
            self.id = id
            self.firstname = firstname
            self.lastname = lastname
            self.email = email
            self.userType = userType
        }
    }
}

// MARK: - Extensions

extension User: PostgreSQLUUIDModel {} // Conform the Fluent's Model
extension User : Content {} // Conform Content
extension User : Parameter {} // Conform Parameter



extension User {
    
    // Children 
    var adsOfUser : Children<User, Ad> { // 1
        return children(\.userID) // 2
    }
    var hearts : Children<User, Heart> { // 1
         return children(\.userID) // 2
     }
    
    // Siblings
    
    /// Computed property to return user models (friends): Relationships which the user initiated.
    var myFriends : Siblings<User, User, UserUserPivot> { // 3
        return siblings(UserUserPivot.leftIDKey, UserUserPivot.rightIDKey) // 4
    }
    /// Computed property to return user models where the selected user is friend: Relationships which the other user initiated.
    var friendOf : Siblings<User, User, UserUserPivot
        > { // 3
        return siblings(UserUserPivot.rightIDKey, UserUserPivot.leftIDKey) // 4
    }
    
    
    /** # This method soft deletes child models of the user  and sibling models of the user what is going to be deleted. Call this method before deleting the user.
     - Parameters:
        - on req: request
        - user: the user what will be removed
     - Throws: AbortError
     - Returns: Future Void (nothing)
     
    1. Query tokens of the user and delete them. Catch errors and print a message.
    2. Query pivots of the user and delete them. Catch errors and print a message.
    3. Return and Query the pivots of the user and delete them, transform to void. Catch errors and print a message.
 */
       func willSoftDelete(on req: Request, user: User) throws -> Future<Void> { // 1
       
        _ = try user.authTokens.query(on: req).delete().catch({ error in
             print(error, "Can't delete the tokens")
        })
        
        _ = user.friendOf.detachAll(on: req).catch({ error in
             print(error, "Can't detach the user from the relationship")
        })
        
        return user.myFriends.detachAll(on: req).catch({ error in
                    print(error, "Can't detach the user from the relationship")
            }).transform(to: ())
            
       }
                   
    
}

/*
 Conform Migration
 
 - Making emails unique
 1. Create the User table
 2. Add all the columns to the User table using User's properties
 3. Add a unique index to email on User
 
 */
extension User: Migration {
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in // 1
            try addProperties(to: builder) // 2
            builder.unique(on: \.email) // 3
        }
    }
}


extension User.Public: Content {} // Conforms User.Public to Content, allowing you ro return the public view in responses.

/*
 1. Defien a method on User that returns User.Publi
 2. Crete a public version of the current object
 */

extension User {
    func convertToPublic() -> User.Public { // 1
        return User.Public(id: id, firstname: firstname, lastname: lastname, email: email, userType: userType) // 1
    }
}

/*
 Extension allows you to call convertToPublic() on Future<User> which helps tidy up your code and reduce nesting. Allow you to vhange your route handlers to return public users.
 1. Define an extension for Future<User>.
 2. Define a new method that returns a Future<User.Public>
 3. Unwrap the user contained in self.
 4. Convert the User object to User.Public
 */

extension Future where T: User { //1
    func convertToPublic() -> Future<User.Public> { // 2
        return self.map(to: User.Public.self) { user in // 3
            return user.convertToPublic() // 4
        }
    }
}

/*
 1. Conform User to BasicAuthenticatable
 2. Tell Vapor which key path of User is the username
 3. Tell Vaor which key path of User if the password
 */

extension User: BasicAuthenticatable { // 1
    static let usernameKey: UsernameKey = \User.email // 2
    static let passwordKey: PasswordKey = \User.password // 3
}

/*
 1. Conform User to TokenAuthenticatable. Allows a token to authenticate a user.
 2. Tell Vapor what type a token is.
 */

extension User: TokenAuthenticatable { // 1
    typealias TokenType = Token // 2
}

/*
 Create an Admin user when Application first boots up.
 1. Defien a new type that conforms to Migration.
 2. Defien which database type this migration is for.
 3. Implement the required prepare(on:).
 4. Create a password hash and terminate with a fatal error if this fails.
 5. Create a new user with the name Admin, username admin, the hashed password and userType: .admin.
 6. Save the user and transform the result to Void, the return type of prepare(on:).
 7. Implement the required revert(on:). .done(on:) returns a pre-completed Future<Void>.
 TODO: - Password update: You can either read an enviromental variable or generate a random password and print it out. 
 */

// 1
struct AdminUser: Migration {
    // 2
    typealias Database = PostgreSQLDatabase
    // 3
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        // 4
        let password = try? BCrypt.hash("password")
        guard let hashedPassword = password else {
            fatalError("Failed to create admin user")
        }
        // 5
        let user = User(firstname: "Admin",
                        lastname: "Admin",
                        email: "admin@admin.admin",
                        password: hashedPassword,
                        userType: .admin)
        // 6
        return user.save(on: connection).transform(to: ())
    }
    // 7
    static func revert(on connection: PostgreSQLConnection) -> Future<Void> {
        return .done(on: connection)
    }
}


extension User : PasswordAuthenticatable {} // Conform User to PasswordAuthenticatable. Allows Vapor to authenticate users with a uername and password when they log in.

extension User : SessionAuthenticatable {} // Conform User to SessionAuthenticatable. Allows the application to save and retrieve your users as part of a session

