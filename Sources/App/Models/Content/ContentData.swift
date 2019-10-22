//
//  ContentData.swift
//  App
//
//  Created by Sötnos on 22/10/2019.
//

import Foundation
import Vapor 

// MARK: - DATATYPES

/// CityWithDepartment Datatype contains the city and the department of the city
/// - city
/// - department
struct CityWithDepartment : Content {
    let city : City
    let department : Department
}

/**
 # AdsOfPerimeterData
 - ads: Array of AdObjects
 - selectedDepartment : Department what was used to make a query
 */
struct AdsOfPerimeterData : Content {
    let ads : [AdObject]
    let selectedDepartment : Department
}

/**
 # New Datatype : AdObject
 - note : Note of the Ad
 - adID : The id of the ad
 - demands : Demands of the Ad
 - offers : Offers of the Ad
 - city : City of the Ad
 - department : Department of the City
 */
struct AdObject : Content {
    let note : String
    let adID : UUID
    let demands : [Demand]
    let offers : [Offer]
    let city : City
    let department : Department
}

/**
 A New Datatype : AdData
 - note : Note of the Ad
 - adID : Id of the Ad
 - images : array of images names
 - demnds : Demands of the Ad
 - offers : Offers of the Ad
 - department : Department of the City
 - city : City of the Ad
 - hearts : Count of the Hearts of the Ad
 - createdAt : The date when the ad was created
 - userID : The owner of the ad
 */

struct AdData : Content {
    let note : String
    let adID : UUID
    let images : [String]?
    let demands : [Demand]
    let offers : [Offer]
    let department : Department
    let city : City
    let hearts : Int
    let createdAt : String
    let userID : UUID
    
}

/**
 # CreateAdData - Data type (contains data to create a new ad)
 - note : A note (string) of ad
 - cityID : Id of the city of the ad
 */
struct CreateAdData : Content {
    let note : String
    let cityID : UUID
}



/**
# A New Datatype : AdOfUserData
 - adID : Id of the Ad
 - note : Note of the Ad
 - images : array of images names
 - demnds : Demands of the Ad
 - offers : Offers of the Ad
 - city : City of the Ad
 - hearts : Count of the Hearts of the Ad
 - createdAt : The date when the ad was created
*/
struct AdOfUserData : Content {
    let adID : UUID
    let note : String
    let images : [String]?
    let demands : [Demand]
    let offers : [Offer]
    let city : City
    let hearts : Int
    let createdAt : String
}

/**
# A New Datatype : AdInfoPostData
 - note : Note of the Ad
 - adID : Id of the Ad
 - demnds : Demand strings of the Ad
 - offers : Offer strings of the Ad
 - city : Name of the City
 - cityID : The ID of the city
 - departmentID : The ID of the department
*/
struct AdInfoPostData : Content {
    let note : String
    let adID : UUID
    let demands : [String]
    let offers : [String]
    let city : String
    let cityID : UUID
    let departmentID : UUID
}

/** # Data type contains data to update an existing city
 - newName : String = Name of the city
 - cityID : UUID = Id of the city
 - departmentID : UUID = Id of the parent(deparment) of the city
 */
struct EditCityData : Content {
    let newName : String
    let cityID : UUID
    let departmentID : UUID
}

/**
 # A New Datatype : AdWithUSer
 - ad :  the Ad
 - user : Public representation of the owner
 - demnads : Demands of the Ad
 - offers : Offers of the Ad
 - city : City of the Ad
 - department : Department of the City
 - hearts : Count of the Hearts of the Ad
 - createdAt : The date when the ad was created
*/

struct AdWithUser : Content {
    let ad : Ad
    let user : User.Public
    let demands : [Demand]
    let offers : [Offer]
    let city : City
    let department : Department
    let hearts : Int
    let createdAt : String

}

/**
 # CountryWithDepartments
 - country : <Country>
 - departments : <[Department]>
 */
struct CountryWithDepartments : Content {
    let country : Country
    let departments : [Department]
}

/**
 # DemandOfferData
 - strings : [String] (Demands/Offers)
 - adID : ID of the ad
 */
struct DemandOfferData : Content {
    let strings : [String]
    let adID : UUID
}

/**
 # DepartmentWithPerimeter
 - department : Department
 - perimeter : [Department]
 */
struct DepartmentWithPerimeter : Content {
    let department : Department
    let perimeter : [Department]
}

// MARK: - New Data Tyeps : AWSController

/// # ImageData
/// - image : Data
/// - adID : Optional Ad ID
struct ImageData : Content {
    let image : Data
    let adID : UUID?
}

/// # Link Data
/// - imageLink : Generated link to the image
/// - imageName : A name of the image
struct LinkData : Content {
    let imageLink : String
    let imageName : String
}

// MARK: - UserController

/// # Datatype which contains user credentials
/// - username : String
/// - password : String

struct LoginPostData : Content {
    let username : String
    let password : String
}


///# UserData contains data to update the user data
/// - first name : String
/// - lastname : String
/// - email : String
struct UserData : Content {
    let firstname : String
    let lastname : String
    let email : String
}

/// # Datatype which contains user credentials to update the password
/// - oldPassword : String
/// - newPassword : String

struct PasswordData : Content {
    let oldPassword : String
    let newPassword : String
}
/// # RegisterPostData
/// - password : String
/// - firstname : String
/// - lastname : String
/// - email : String
struct RegisterPostData : Content {
    let password : String
    let firstname : String
    let lastname : String
    let email : String
}

/// # Datatype which contains data to accept the contact request from the other user
/// - userID : Id of the user
/// - accepted : Bool
struct ContactRequestData : Content {
    let userID : User.ID
    let accepted : Bool
}

/// # Datatype which contains data to see the contact request.
/// - userID : id of the user
/// - name : firstname of the user
struct ContactRequestFromData : Content {
    let userID : UUID
    let firstname : String
}

/**
 # ContactContext
 - csrfToken : Optional String that we use against csrf attacks
 - contactID : The id of the contact of the ad
 - firstname : Optional firstname
 - lastname : Optional lastname
 - emal : Optional email
 - youAccepted : Optional boolen value which  defines if the user has accepted/sent a request
 - otherAccepted: Optional boolean value which defines if other has accepted/sent a request
 */
struct ContactData : Content {
    let contactID : UUID
    let firstname : String?
    let lastname : String?
    let email : String?
    let youAccepted : Bool
    let otherAccepted : Bool
}

/**
 # TokenData
 - token : Token
 - usertype : String
 */
struct TokenData : Content {
    let token : Token
    let usertype : String
}

/**
 # ContactInfoData
 - contact : User.Public
 - ads : [Ad]
 */
struct ContactInfoData : Content {
    let contact : User.Public
    let ads : [Ad]
}

