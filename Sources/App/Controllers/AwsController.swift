//
//  AwsController.swift
//  App
//
//  Created by Sötnos on 06/08/2019.
//

import S3
import Vapor
import FluentPostgreSQL

/// Class responsible for handling AWS S3
final class AwsController: RouteCollection {
    
    // MARK: - Properties
    private let awsConfig: AwsConfig
    
    // MARK: - Inits
    init(awsConfig: AwsConfig) {
        self.awsConfig = awsConfig
    }
    
    // MARK: - Instance methods
    func boot(router: Router) throws {
        
        /// 1. Create a TokenAuthenticationMiddleware for User. This uses BearerAuthenticationMiddleware to extract the bearer token out of the request. The middleware then convert            s this token into a logged in user.
        /// 2. Create a GuardAuthMiddleware. Error to throw if the type is not authed.
        /// 3. Create an adminGroup for routes which requires that the user has an admin access. (Right now all actions) Create the group using tokenAuthMiddleware and guardAuthMiddleware and also AdminMiddleware() to protect the route for creating a user with token authentication.
        
        let group = router.grouped(Path.base.rawValue) // aws
        let tokenAuthMiddleware = User.tokenAuthMiddleware() // 1
        let guardAuthMiddleware = User.guardAuthMiddleware() // 2
        let adminGroup = group.grouped(tokenAuthMiddleware, guardAuthMiddleware, AdminMiddleware()) // 3
      
        /// 1. POST Request : Protected route to post image data to AWS S3 Bucket.
        /// 2. GET Request : Unprotected route to get images of the selected ad.
        adminGroup.post(ImageData.self, at: "image", use: postImageHandler) // 1
        group.get(Ad.parameter, "images", use: getImageUrlsHandler) // 2
    }
    
    // MARK: - AWS Route Handlers
    
    /// Route handler to post an image to the presignedURl (to the AWS S3 Bucket).
    /// 1. Method takes a request and ImageData as a parameters.
    /// 2. Decode the content of the request to the ImageData. After completion handler is completed, flatMap the data to Future<Response>.
    /// 3. Unwrap the ad id.
    /// 4. Get the url by calling the preparePresignedUrl -method.
    /// 5. Make a client to make a http request.
    /// 6. Make a put reques to the url and before sending execute the completion handler.
    /// 7. In the completion handler add headers to the request.
    /// 8. In the completion handler convert the image data to HTTPBody.
    /// 9. In the completion handler specify the MediaType to be .png.
    /// 10. Map the response of the request to be Future<Response> and execute the completion handler.
    /// 11. If the http status code is 200, request was completed succesfully (image was saved).
    /// 12. Otherwise print the status code with a message.
    /// 13. Return the response.
    
    func postImageHandler(_ req: Request, data: ImageData) throws -> Future<Response> { // 1
        
        return try req.content.decode(ImageData.self).flatMap(to: Response.self) { data in // 2
            
            guard let id = data.adID else {throw Abort(.internalServerError)} // 3
            
            let url = try self.preparePresignedUrl(request: req, ad: id) // 4
            let client = try req.make(Client.self) // 5
            
            return client.put(url, beforeSend: { requestAWS in // 6
                
                requestAWS.http.headers.add(name: "x-amz-acl", value: "public-read") // 7
                requestAWS.http.body = data.image.convertToHTTPBody() // 8
                requestAWS.http.contentType = .png // 9
                
            }).map(to: Response.self) { res in // 10
                if res.http.status.code == 200 { // 11
                    print("Item created", res.http.status.code)
                    
                } else {
                    print("Error: Couldn't save the image.", res.http.status.code) // 12
                }
                return res // 13
            }
        }
    }
    
    /// A Method to get the url to display the image file what is stored in Amazon Web Service S3 -bucket.
    /// 1. Function takes in a request and returns an array of future strings.
    /// 2. Making a s3 signer.
    /// 3. An empty array of urls what is created to store the image urls.
    /// 4. Extract the ad from the request's parameters and unwrap the result.
    /// 5. In Compeltion Hnadler: Get the images of the ad (array of stings which are names of the images). Unwrap the result.
    /// 6. Loop filenames.
    /// 7. Make a baseUtrl constant to store an awsConfig's url -property.
    /// 8. Make a imagePath constant to store the awsConfig's imagePaht -property.
    /// 9. Create an url from the baseURL.
    /// 10. Append a path component (imagePath) to the url.
    /// 11. Append a path component (file) to the url.
    /// 12. Create a pre-signed URL by passing the parameters to the method. for: - GET request, url: is the url we created, expiration: The pre-signed url expires in one hour of the creation.
    /// 13. Return the absolute string for the URL and unwrap the optional.
    /// 14. Add the absolute string to the url -array.
    /// 15. Return the array of future stings (= urls).

    func getImageUrlsHandler(_ req: Request) throws -> Future<[String]> { // 1
        
        let s3 = try req.makeS3Signer() // 2
        var urls = [String]() // 3
        return try req.parameters.next(Ad.self).map(to: [String].self) { ad in // 4
            
            guard let filenames = ad.images else {throw Abort(.internalServerError)} // 5
            
            for file in filenames { // 6

                let baseUrl = self.awsConfig.url // 7
                let imagePath = self.awsConfig.imagePath // 8
                
                guard var url = URL(string: baseUrl) else { // 9
                    throw Abort(.internalServerError)
                }
                
                url.appendPathComponent(imagePath) // 10
                url.appendPathComponent(file) // 11
            
                let result = try s3.presignedURL(for: .GET, url: url, expiration: Expiration.hour) // 12
                
                // 13
                guard let presignedUrl = result?.absoluteString else {
                    throw Abort(.internalServerError)
                }
                urls.append(presignedUrl) // 14
            }
            return urls // 15
        }
    }
}


// MARK: - Extension with preparePresignedUrl method
/// Private extension for AwsController for Aws Handlers (Amazon Web Servcies)
private extension AwsController {
    
    /// Method to prepare presigned URL to put an image to the AWS S3 Bucket
    /// 1. Prepares presigned URL, user should send PUT request with image to this URL
    /// 2. Make a baseUtrl constant to store an awsConfig's url -property.
    /// 3. Make a imagePath constant to store the awsConfig's imagePaht -property.
    /// 4. Make a newFilename by creating a random UUID string + ".ping"
    /// 5. Create an url from the baseURL.
    /// 6. Append a path component (imagePath) to the url.
    /// 7. Append a path component (newFilename) to the url.
    /// 8. Create a headers for the PUT request.
    /// 9. Make a S3 signer to create a presignet url
    /// 10. Try to create a a presigned url (Url is for PUT -request. Url is created url. The url expires after one hour. Pass the headers in.)
    /// 11. Make an url from the result string.
    /// 12. In the do catch -block try to ad the newFilename to the ad by calling an adImage -method.
    /// 13. If errors occur, catch them and print out.
    /// 14. Return the presignedUrl.
    func preparePresignedUrl(request: Request, ad: UUID) throws -> String { // 1
        
        let baseUrl = awsConfig.url // 2
        let imagePath = awsConfig.imagePath // 3
        let newFilename = UUID().uuidString + ".png" // 4
        
        guard var url = URL(string: baseUrl) else { // 5
            throw Abort(.internalServerError)
        }
        
        url.appendPathComponent(imagePath) // 6
        url.appendPathComponent(newFilename) // 7
        let headers = ["x-amz-acl": "public-read"] // 8
        
        let s3 = try request.makeS3Signer() // 9
        let result = try s3.presignedURL(for: .PUT, url: url, expiration: Expiration.hour, headers: headers) // 10
      
        guard let presignedUrl = result?.absoluteString else { // 11
            throw Abort(.internalServerError)
        }
        do { // 12
            _ = try self.adImage(newFilename, to: ad, on: request)
        } catch let error { // 13
            print("Errors catched: The Error occured when saving filenames.", error)
            throw Abort(.internalServerError)
        }
        return presignedUrl // 14
    }
    
    /// Private Method to save image names to the ad.
    /// 1. Helper method takes a string parameter(a name of the file), uuid(an id of the ad) and the request in as parameters. Returns Void.
    /// 2. Make a database query to the Ad table: Filter results with the ad id and get the first result. After completion handler flatMap the response to Future<Void>.
    /// 3. If foundAd equals exisitngAd ie. look if the ad with the required id was found. (unwrap foundAd)
    /// 4. If the ad doesn't have images.
    /// 5. Ad an array of string(name) to be images.
    /// 6. Save the updated ad and transform to the void.
    /// 7. If the ad has already images.
    /// 8. Append the new name to the images.
    /// 9. Save the updated ad and transform to the void.
    private func adImage(_ name: String, to id: UUID, on req: Request) throws -> Future<Void> { // 1

        return Ad.query(on: req).filter(\Ad.id == id).first().flatMap(to: Void.self) { foundAd in // 2
            
            guard let existingAd = foundAd else {throw Abort(.internalServerError)} // 3
     
            if existingAd.images == nil { // 4
                existingAd.images = [name] // 5
                return existingAd.save(on: req).transform(to: ()) // 6
            } else { // 7
                existingAd.images!.append(name) // 8
                return existingAd.save(on: req).transform(to: ()) // 9
            }
        }
    }
}


/// ImageData is new data type which contains:
/// - image : Data
/// - adID : Optional Ad ID
struct ImageData : Content {
    let image : Data
    let adID : UUID?
}

