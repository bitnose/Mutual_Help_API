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
        /// 4. A group whihc requires that the user has an admin access OR standard access, otherwise it throws an abort(.forbidden).
        
        let group = router.grouped(Path.base.rawValue) // aws
        let tokenAuthMiddleware = User.tokenAuthMiddleware() // 1
        let guardAuthMiddleware = User.guardAuthMiddleware() // 2
        let tokenAuthGroup = group.grouped(tokenAuthMiddleware, guardAuthMiddleware) // 4
      
        // 1. Post Request : POST FILE TO S3 BUCKET
        // 2. Get Request : GET FILE URLS OF THE SELECTED AD
        // 3. Get Request : GET URLS TO DELETE FILE FROM S3 BUCKET
        tokenAuthGroup.post("image", use: postImageHandler) // 1
        group.get(Ad.parameter, "images", use: getImageUrlsHandler) // 2
        tokenAuthGroup.get(Ad.parameter, "images", "delete", String.parameter, use: deleteFileHandler) // r
    }
    
    // MARK: - AWS Route Handlers
    
    /// # Route handler to post an image to the presignedURl (to the AWS S3 Bucket).
    /// 1. Method takes a request and ImageData as a parameters.
    /// 2. Decode the content of the request to the ImageData. After completion handler is completed, flatMap the data to Future<Response>.
    /// 3. Unwrap the ad id.
    /// 3.a) Look if the user has the ad which is the same as the adID from the request. If it doesn't exists throw an abort (.forbidden).
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
    
    func postImageHandler(_ req: Request) throws -> Future<Response> { // 1
        
    
        return try req.content.decode(ImageData.self).flatMap(to: Response.self) { data in // 2
        
            let user = try req.requireAuthenticated(User.self)
         
            guard let id = data.adID else {throw Abort(.internalServerError)} // 3
            
            let _ = try user.adsOfUser.query(on: req).filter(\Ad.id == id).first().unwrap(or: Abort(.forbidden)) // 3a
            
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
    
    /// # A Method to get the url to display the image file that is stored in the Amazon Web Service S3 -bucket.
    /// 1. Function takes in a request and returns an array of future LinkData.
    /// 2. Making a s3 signer.
    /// 3. An empty array of LinkData what is created to store the LinkData.
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
    /// 14. Create a LinkData object and add it to the data -array.
    /// 15. Return the array of LinkData.

    func getImageUrlsHandler(_ req: Request) throws -> Future<[LinkData]> { // 1
        
        let s3 = try req.makeS3Signer() // 2
        
        var data = [LinkData]() // 3
        
        return try req.parameters.next(Ad.self).map(to: [LinkData].self) { ad in // 4
            
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
               // 14
                let linkdata = LinkData(imageLink: presignedUrl, imageName: file)
                data.append(linkdata)
                
            }
            return data // 15
        }
    }
    
    /// # Route Handler to delete image from the aws bucket
    /// 1. Route handler returns Future<Response>.
    /// 2. Extract an id of the ad from the request's parameters.
    /// 3. Extract a name of the file from the request's paramers.
    /// 4. Call another  method to update the ad model (remove the image name of from the ad's images array). Parameters are an imageName, a request and a future<Ad>.
    /// 5. Make a presigned url to delete ad by calling a method which takes the request and the imageName as parameters.
    /// 6. Make a client.
    /// 7. Make a delete request using the presignedURL.
    /// 8. Before sending the request add the http headers.
    /// 9. Map a future to a Future<Response>.
    /// 10. Look it the response http status code is 204.
    /// 11. If yes it means that the file is deleted successfully. Print the status code and a message.
    /// 12. If the status code is not 204 ie if it's something else.
    /// 13. Print a message and the http status code. In this case the deletion wasn't successfull.
    /// 14. Return a response.
    func deleteFileHandler(_ req: Request) throws -> Future<Response> { // 1
     
        let ad = try req.parameters.next(Ad.self) // 2
        let name = try req.parameters.next(String.self) // 3
       
    
        _ = try Ad.removeImage(name: name, to: ad, req: req).catchMap({ error in
            print(error)
            throw Abort(.forbidden)
        }) // 4
        
        let presignedURL = try self.preparePresignedDeleteUrl(request: req, imageName: name) // 5
        let client = try req.make(Client.self) // 6
        
        return client.delete(presignedURL, beforeSend: { requestAWS in // 7
            
            requestAWS.http.headers.add(name: "x-amz-acl", value: "public-read") // 8
            
        }).map(to: Response.self) { res in // 9
            if res.http.status.code == 204 { // 10
                print("Item deleted", res.http.status.code) // 11
                
            } else { // 12
                print("Error with deleting image", res.http.status.code) // 13
            }
            return res // 14
        }
    }
    
    
    /// # Route Handler to delete image from the aws bucket
    /// 1. Route handler returns Future<Response>.
    /// 2. Make a presigned url to delete ad by calling a method which takes the request and the imageName as parameters.
    /// 3. Make a client.
    /// 4. Make a delete request using the presignedURL.
    /// 5. Before sending the request add the http headers.
    /// 6. Map a future to a Future<Response>.
    /// 7. Look it the response http status code is 204.
    /// 8. If yes it means that the file is deleted successfully. Print the status code and a message.
    /// 9. If the status code is not 204 ie if it's something else.
    /// 10. Print a message and the http status code. In this case the deletion wasn't successfull.
    /// 12. Return a response.
    func deleteFile(_ req: Request, name: String) throws -> Future<Response> { // 1
        
        let presignedURL = try self.preparePresignedDeleteUrl(request: req, imageName: name) // 2
        let client = try req.make(Client.self) // 3
        
        return client.delete(presignedURL, beforeSend: { requestAWS in // 4
            
            requestAWS.http.headers.add(name: "x-amz-acl", value: "public-read") // 5
            
        }).map(to: Response.self) { res in // 6
            if res.http.status.code == 204 { // 7
                
                print("Item deleted", res.http.status.code) // 8
                
            } else { // 9
                print("Error with deleting image", res.http.status.code) // 10
            }
            return res // 11
        }
    }
}


// MARK: - This extension consists of Methods to Prepare urls
/// Private extension for AwsController for Aws Handlers (Amazon Web Servcies)
private extension AwsController {
        
    /// # Method to prepare presigned URL to put an image to the AWS S3 Bucket
    /// 1. Prepares presigned URL, user should send PUT request with image to this URL
    /// 2. Make a baseUrl constant to store an awsConfig's url -property.
    /// 3. Make a imagePath constant to store the awsConfig's imagePaht -property.
    /// 4. Make a newFilename by creating a random UUID string + ".ping"
    /// 5. Create an url from the baseURL.
    /// 6. Append a path component (imagePath) to the url.
    /// 7. Append a path component (newFilename) to the url.
    /// 8. Create a headers for the PUT request.
    /// 9. Make a S3 signer to create a presignet url
    /// 10. Try to create a a presigned url (Url is for PUT -request. Url is created url. The url expires after one hour. Pass the headers in.)
    /// 11. Make an absolute string from the result string.
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
            _ = try Ad.adImage(name: newFilename, to: ad, req: request)
        } catch let error { // 13
            print("Errors catched: The Error occured when saving filenames.", error)
            throw Abort(.internalServerError)
        }
        return presignedUrl // 14
    }
    
    
    /// # Method to prepare url to delete a file
    /// 1. Parameters: Request & String (a name of the image) and return a string
    /// 2. Make a baseUrl constant to store an awsConfig's url -property.
    /// 3. Make a imagePath constant to store the awsConfig's imagePaht -property.
    /// 4. Create an url from the baseURL.
    /// 5. Append a path component (image path) to the url.
    /// 6. Append a path component (a name of the selected image) to the url.
    /// 7. Create a headers for the request.
    /// 8. Make a S3 signer to create a presignet url
    /// 9. Create a presigned url for later use. This url is for deleting a file from the bucket and the url expires after one hour.
    /// 10. Make an absolute string from the result string.
    func preparePresignedDeleteUrl(request: Request, imageName: String) throws -> String { // 1
        
        let baseUrl = awsConfig.url // 2
        let imagePath = awsConfig.imagePath // 3

        guard var url = URL(string: baseUrl) else { // 4
            throw Abort(.internalServerError)
        }
        url.appendPathComponent(imagePath) // 5
        url.appendPathComponent(imageName) // 6
        let headers = ["x-amz-acl": "public-read"] // 7
        
        let s3 = try request.makeS3Signer() // 8
        let result = try s3.presignedURL(for: .DELETE, url: url, expiration: Expiration.hour, headers: headers) // 9
        
        guard let presignedUrl = result?.absoluteString else { // 10
            throw Abort(.internalServerError)
        }
        return presignedUrl // 11
    }
}

