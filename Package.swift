// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Mutual_Help_API",
    products: [
        .library(name: "Mutual_Help_API", targets: ["App"]),
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
        // Swift ORM (queries, models, relations, etc) built on PostgreSQL
        .package(url: "https://github.com/vapor/fluent-postgresql.git", from: "1.0.0-rc"),
        // Authenticatio package
        .package(url: "https://github.com/vapor/auth.git", from: "2.0.0"),
        // VaporExt – this helps us with storing environmental variables
        .package(url: "https://github.com/vapor-community/vapor-ext.git", from: "0.1.0"),
        // S3 – this manages generating presigned URLs for us.
        .package(url: "https://github.com/mlubgan/S3.git", .revision("589ae7fea85bfb7f8ec23eb55664df67db289c49")),
        // LoggerAPI - To prevent to avoid a logging conflict
        .package(url: "https://github.com/IBM-Swift/LoggerAPI.git", .upToNextMinor(from: "1.8.0")),
        // Swift-SMTP For sending emails
        .package(url: "https://github.com/IBM-Swift/Swift-SMTP", .upToNextMinor(from: "5.1.0"))
        //
        

        
    ],
    targets: [
        .target(name: "App", dependencies: ["FluentPostgreSQL", "Vapor", "Authentication", "VaporExt", "S3", "LoggerAPI", "SwiftSMTP"]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)

