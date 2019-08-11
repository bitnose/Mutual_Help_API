//
//  AwsConfig.swift
//  App
//
//  Created by Sötnos on 06/08/2019.
//

import VaporExt
import S3

// MARK: - Class responsible for holding AWS config
public struct AwsConfig {
    
    var url: String
    var imagePath: String
    var name: String
    var accKey: String
    var secKey: String
    var region: Region
    
}

// MARK: - Class responsible for providing correct AWS configuration
// A class responsible for unwrapping the .env file and registering a S3 service.
class AwsConfiguration {
    
    // MARK: - Instance Methods
    func setup(services: inout Services) throws -> AwsConfig {
        Environment.dotenv(filename: Keys.filename)
        guard
            let url: String = Environment.get(Keys.url),
            let imagePath: String = Environment.get(Keys.imagePath),
            let name: String = Environment.get(Keys.name),
            let accKey: String = Environment.get(Keys.accKey),
            let secKey: String = Environment.get(Keys.secKey),
            let regionString: String = Environment.get(Keys.region) else {
                fatalError("Missing values in .env file")
        }
        
        guard let regionName = Region.RegionName(rawValue: regionString) else {
            fatalError("Incorrect region in .env file")
        }
        let region = Region(name: regionName)
        
        let config = AwsConfig(
            url: url,
            imagePath: imagePath,
            name: name,
            accKey: accKey,
            secKey: secKey,
            region: region
        )
        
        let s3Config = S3Signer.Config(
            accessKey: accKey,
            secretKey: secKey,
            region: region
        )
        
        try services.register(
            s3: s3Config,
            defaultBucket: name
        )
        
        return config
    }
}

// MARK: - Extension with keys used in .env file
private extension AwsConfiguration {
    
    struct Keys {
        
        private init() { }
        
        static let filename = "aws-config.env"
        static let url = "BUCKET_URL"
        static let imagePath = "BUCKET_IMGPATH"
        static let name = "BUCKET_NAME"
        static let accKey = "BUCKET_ACCKEY"
        static let secKey = "BUCKET_SECKEY"
        static let region = "BUCKET_REGION"
    }
}
