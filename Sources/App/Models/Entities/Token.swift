//
//  Token.swift
//  App
//
//  Created by Sötnos on 03/07/2019.
//

import Foundation
import Vapor
import FluentPostgreSQL
import Authentication

/*
 Define a model for Token that contains the following properties:
 - id : the ID of the model
 - token : the token string provided to clients
 - userID : the token ownerär user ID. The migration also creates a foreign key constraint with User.
 */


final class Token: Codable {
    var id: UUID?
    var token: String
    var userID: User.ID
    
    init(token: String, userID: User.ID) {
        self.token = token
        self.userID = userID
    }
}

extension Token: PostgreSQLUUIDModel {}


/*
 Setting up the Foreign Key Constraints
 1. Conform the Model to Migration
 2. Implement prepare(on:) as required by Migration. This overrides the default implementation.
 3. Create the table for Ad in the database
 4. Use addProperties(to:) to add all the fields to the database. This means you don't need to add each column manually.
 5. Add a reference between the adID property on Ad and the id property on Ad. This sets up the foreign key constraint between the two tables
 */

extension Token: Migration {
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            builder.reference(from: \.userID, to: \User.id)
        }
    }
}

extension Token: Content {}

/*
 1. Define a static function to generate a token for a user
 2. Generate 16 random bytes to act as the token
 3. Create a Token using the based64-encoded representation of the random bytes and the user's ID
 */

extension Token {
    static func generate(for user: User) throws -> Token { // 1
        let random = try CryptoRandom().generateData(count: 16) // 2
        return try Token(token: random.base64EncodedString(), userID: user.requireID()) // 3
    }
}

/*
 1. Conform Token to Authentication's Token protocol.
 2. Define the user ID key on Token.
 3. Tell Vapor what type the user is.
 4. Conform Token to BearerAuthenticatable. This allows you to use Token with bearer authentication. Bearer authenticatio is a mechanism for sending a token to authenticate requests. It uses Authorization header, like HTTP basic authentication, but the header looks like Authorization : Bearer <TOKEN STRING>.
 5. Tell Vapor the key path to the token key, in this case, Token's token string.
 
 */
extension Token: Authentication.Token { // 1
    static let userIDKey: UserIDKey = \Token.userID // 2
    typealias UserType = User // 3
}

extension Token: BearerAuthenticatable { // 4
    static let tokenKey: TokenKey = \Token.token // 5
}


