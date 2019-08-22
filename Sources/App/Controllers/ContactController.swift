//
//  ContactController.swift
//  App
//
//  Created by Sötnos on 03/07/2019.
//

import Foundation
import Vapor
import Fluent

struct ContactController : RouteCollection {
    
    // MARK: - Register Routes
    func boot(router: Router) throws {
        let contactRoutes = router.grouped("api/contacts")
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let adminGroup = contactRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware, AdminMiddleware())
        
        /*
         Create a new route path for the api/ads
         
         - Grouped Route (/api/ads) +  Request Type (POST, GET, PUT, DELETE) (+ Path component + Method)
         
         1. Post Request - Post route with method which creates a new Contact
         2. Get Request - Retrieve all Contacts
         3. Delete Request - Delete Contact by ID
         4. Get Request - Get the contact by ID
         5. Put Request - Update the existing contact
         */
        
        adminGroup.post( use: createHandler) // 1
        contactRoutes.get(use: getAllHandler) // 2
        contactRoutes.delete(Contact.parameter, use: deleteHandler) // 3
        contactRoutes.get(UUID.parameter, use: getContactHandler) // 4
        adminGroup.put(Contact.parameter, "update", use: updateContactHandler) // 5
        
    }
    
    // MARK: - Handlers
    
    /*
     Create Contact
     1. Function return Future<Contact>
     2. Decode the request's JSON into an object. This is simple because the Model conforms to Content. Decode returns a Future; use flatMap(to:) to extract the object when decoding completes.
     3. Save the object.
     */
    
    func createHandler(_ req: Request) throws -> Future<Contact> { // 1
        return try req.content.decode(Contact.self).flatMap(to: Contact.self) { contact in // 2
            print(contact.contactName)
            return contact.save(on: req) // 3
        }
      
    }
    
    /* Retrieve All Contacts
     1. Only parameter is request itself
     2. Perform Query to Retrieve All (Fluent adds functions to models to be able to perform queries on them. Provides a thread to perform the work.) Function fetches all Objects from the table and returns an array of Objects
     */
    
    func getAllHandler(_ req: Request) throws -> Future<[Contact]> { // 1
        return Contact.query(on: req).all() // 2
    }
    
    
    /*
     Delete by ID
     1. Method to DELETE to that returns Future<HTTPStatus>
     2. Extract the Object to delete from the request’s parameters.
     3. Delete the Object using delete(on:). Instead of requiring you to unwrap the returned Future, Fluent allows you to call delete(on:) directly on that Future. This helps tidy up code and reduce nesting. Fluent provides convenience functions for delete, update, create and save.
     4. Transform the result into a 204 No Content response. This tells the client the request has successfully completed but there’s no content to return.
     */
    
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> { // 1
        return try req.parameters.next(Contact.self) // 2
            .delete(on: req) // 3
            .transform(to: .noContent) // 4
    }
    
    /// Get contact by ID
    /// 1. Extract the UUID to get from the request’s parameters.
    /// 2. Make a query to the Contact table and filter the result with the extracted id.
    /// 3. If foundContact equals to the existingContact return the existingContact.
    /// 4. Otherwise throw an Abort.
    
    func getContactHandler(_ req: Request) throws -> Future<Contact> {
        
        let id = try req.parameters.next(UUID.self) // 1
        return Contact.query(on: req).filter(\Contact.id == id).first().map(to: Contact.self) { foundContact in // 2
            if let existingContact = foundContact { // 3
                return existingContact // 3
            } else {
                throw Abort(.notFound) // 4
            }
        }
    }
    
    /// Handler to update the existing contact with the new data
    /// 1. Use flatMap(to:_:_:), the dual future form of flatMap, to wait for both the parameter extraction and content decoding to complete.
    /// 2. The contact from the database and updated contact data from the request body to the closure.
    /// 3. Update the contact with the new data.
    /// 4. Save the contact.
    
    func updateContactHandler(_ req: Request) throws -> Future<HTTPResponseStatus> {
        // 1
        return try flatMap(
            to: HTTPStatus.self,
            req.parameters.next(Contact.self),
            req.content.decode(Contact.self)
            // 2
        ) { contact, updatedContact in
            // 3
            contact.adLink = updatedContact.adLink
            contact.contactName = updatedContact.contactName
            contact.facebookLink = updatedContact.facebookLink
            // 4
            return contact.save(on: req).transform(to: .created)
        }
    }

    
    
    
    
}
