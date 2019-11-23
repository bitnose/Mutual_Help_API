//
//  ResetPasswordToken.swift
//  App
//
//  Created by Sötnos on 18.11.2019.
//

import FluentPostgreSQL

/**
 # ResetPasswordToken : To secure a password reset request, you should create a random token and send it to the user.
 - UUID for the ID
 - String for the actual token
 - the user’s ID
 - createdAt : The date when the token was created
 */
final class ResetPasswordToken: Codable {
    var id: UUID?
    var token: String
    var userID: User.ID
    var createdAt : Date?

    // inits
    init(token: String, userID: User.ID) {
        self.token = token
        self.userID = userID
  }
    
     static var createdAtKey: TimestampKey? = \.createdAt
}

// Model must conform PostgreSQLUUIDModel to use the model with the database.
extension ResetPasswordToken: PostgreSQLUUIDModel {}

// Override the default migration to set up a reference to the User table, linking the ID.
extension ResetPasswordToken: Migration {
  static func prepare(on connection: PostgreSQLConnection)
    -> Future<Void> {
      return Database.create(self, on: connection) { builder in
        try addProperties(to: builder)
        builder.reference(from: \.userID, to: \User.id)
      }
  }
}

// Add an extension to make it easy to get the user from a token using Fluen
extension ResetPasswordToken {
  var user: Parent<ResetPasswordToken, User> {
    return parent(\.userID)
  }
}

