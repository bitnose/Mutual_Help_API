//
//  SMTPConfig.swift
//  App
//
//  Created by Sötnos on 15.11.2019.
//

import Foundation
import VaporExt
import SwiftSMTP

// MARK: - Class responsible for getting SMTP secrets from .env file
public struct SMTPConfig {
    
    let host : String
    let port : Int
    let email : String
    let password : String

}
    // MARK: - Class responsible for providing correct SMTP configuration
    // A class responsible for unwrapping the .env file
class SMTPConfiguration {
        
    // MARK: - Instance Methods
    func setup() -> SMTPConfig {
        // Get the .env file
        Environment.dotenv(filename: Keys.filename)
        
        // Fetch the objects from the .env file and unwrap them
        guard
            let host: String = Environment.get(Keys.host),
            let port: Int = Environment.get(Keys.port),
            let email : String = Environment.get(Keys.email),
            let password : String = Environment.get(Keys.password) else { fatalError("Missing values in .env file")}
        // Create a config object by passing the fetched secrets
        let config = SMTPConfig(host: host, port: port, email: email, password: password)
        // Return configurations
        return config
    
    }
}


// MARK: - Extension with keys used in .env file
private extension SMTPConfiguration {
    // Keys to the .env file
    struct Keys {
        
        private init() { }
        
        static let filename = "smtp-config.env"
        static let host = "SMTP_HOST"
        static let port = "SMTP_PORT"
        static let email = "SMTP_EMAIL"
        static let password = "SMTP_PASSWORD"
    }
}
