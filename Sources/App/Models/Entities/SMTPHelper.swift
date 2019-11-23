//
//  SMTP.swift
//  App
//
//  Created by Sötnos on 17.11.2019.
//

import Foundation
import SwiftSMTP

/**
 # SMTPHelper struct is a class responsible of sending emails
    - smtp : SMTP
    - config = SMTPConfiguration instance
 */

final class SMTPHelper {
    
    let smtp : SMTP
    private let config = SMTPConfiguration()
    
    // Inits
    init() {
       // Set up configurations
        let smtpConfig = config.setup()
        self.smtp = SMTP(hostname: smtpConfig.host, email: smtpConfig.email, password: smtpConfig.password, port: Int32(smtpConfig.port), tlsMode: .requireSTARTTLS, tlsConfiguration: nil)
        
    }
    

    /// #Confirmation email
    func sendMail(name: String, email: String) throws {
            
        // Sender of the mail
        let EEGJ = Mail.User(name: "EEGJ", email: config.setup().email)
        // Receiver of the mail
        let name = Mail.User(name: name, email: email)

        //Creating  a mail object
        let mail = Mail(
            from: EEGJ,
            to: [name],
            subject: "Confirmation email",
            text: "Welcome to part of the eegj community! Please confirm your email."
        )

        // Sending the mail and if errors appear then printing them out
            smtp.send(mail) { error in
                if let error = error {
                    print(error, "ei toimi")
                }
            }
        }
    
    
    // MARK: - RESET PASSWORD MAIL
    
    /**
     # RESET PASSWORD MAIL
     - parameters:
        - name : The name of the user
        - email : The email address of the user
     - throws : Abort
      
     1. Method sends an email to the email address and returns nothing.
     2. Add a Sender of the mail
     3. Add a Receiver of the mail
     4. Create a mail object.
     5.  Send the created mail.  In the closure, check if there are any errors, if yes print them out.
     */
    
    func sendResetPasswordEmail(name: String, email: String, resetTokenString:String) { // 1

        let sender = Mail.User(name: "EEGJ", email: config.setup().email) // 2
        let receiver = Mail.User(name: name, email: email) // 3
        
        // 4
        let mail = Mail(
            from: sender,
            to: [receiver],
            subject: "Reset Your Password",
            text: "Hi \(name)!You've requested to reset your password. Click this link to reset your password: https://eegj.fr/resetPassword?token=\(resetTokenString)"
        
        )
        
        // 5
        smtp.send(mail) { error in
            if let error = error {
                print(error, "Couldn't send.")
            }
        }
    }
    
    
}


   
