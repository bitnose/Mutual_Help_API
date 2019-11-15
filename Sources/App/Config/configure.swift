
import Vapor
import FluentPostgreSQL
import Authentication

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {

    /*
     Register providers first:
     1. Register FluentPostgreSQL Provider
     2. Registers the necessary services with your application to ensure authentication works
     */
    
    try services.register(FluentPostgreSQLProvider()) // 1
    try services.register(AuthenticationProvider()) // 2
    /// Configure AWS S3 Signer
    let awsConfig = try AwsConfiguration().setup(services: &services)
  
    // Register routes to the router
    let router = EngineRouter.default()
    try routes(router, awsConfig: awsConfig)
    services.register(router, as: Router.self)

    /*
     Register middlewares
     1. Create _empty_ middleware config
     2. Catches errors and converts to HTTP response
     3. middleware. Enables sessions for all request.
     4. Register the middlewares
     */
    var middlewares = MiddlewareConfig() // 1
    
    middlewares.use(ErrorMiddleware.self) // 2
    middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
 //   middlewares.use(SessionsMiddleware.self) // 2
    services.register(middlewares) // 4
   
    // There is a default limit of 1 million bytes for incoming requests, which you can override by registering a custom NIOServerConfig instance like this:
    
    services.register(NIOServerConfig.default(maxBodySize: 20_000_000))
    // Get the environment keys
     Environment.dotenv(filename: "postgres-config.env")
    
    // Fetch the environment variables
    let databaseName = Environment.get("POSTGRES_DATABASE_NAME", "")
    let hostname = Environment.get("POSTGRES_HOSTNAME", "")
    let databasePort =  Environment.get("POSTGRES_PORT", Int())
    let username =  Environment.get("POSTGRES_USERNAME", "")
    let password = Environment.get("POSTGRES_PASSWORD", "")
    
    /// # Configure a PostgreSQL database
    let databaseConfig = PostgreSQLDatabaseConfig(
        hostname: hostname,
        port: databasePort,
        username: username,
        database: databaseName,
        password: password)
    let database = PostgreSQLDatabase(config: databaseConfig)
    
    // Register the configured PostgreSQL database to the database config.
    var databases = DatabasesConfig()
    databases.add(database: database, as: .psql)
    services.register(databases)
let serverConfig = NIOServerConfig.default(hostname: "0.0.0.0")
services.register(serverConfig)    
    /*
     Configure migrations:
     1. Add Model to the Migration list - Adds the new model to the migrations so Fluent prepares the table in the database
     2. Add Migration to the MigrationConfig : AdminUser
     3. This adds the migration to MigrationConfig so Fluent prepares the database correctly to use the enum. Note this uses add(migration:database:) rather than add(model:database:) since UserType isn’t a model
     */
    
    var migrations = MigrationConfig()
    // 1
    migrations.add(model: Country.self, database: .psql)
    migrations.add(migration: UserType.self, database: .psql) // 3
    migrations.add(model: User.self, database: .psql)
    migrations.add(model: Department.self, database: .psql)
    migrations.add(model: Token.self, database: .psql)
    migrations.add(model: DepartmentDepartmentPivot.self, database: .psql)
    migrations.add(model: City.self, database: .psql)
    migrations.add(model: Ad.self, database: .psql)
    migrations.add(model: CityAdPivot.self, database: .psql)
    migrations.add(model: Demand.self, database: .psql)
    migrations.add(model: Offer.self, database: .psql)
    migrations.add(model: Heart.self, database: .psql)
    migrations.add(model: UserUserPivot.self, database: .psql)
    
    migrations.add(migration: AdminUser.self, database: .psql)  // 2
    services.register(migrations)
    
    
    // Add the Fluent commands to your application, which allows you to manually run migrations and allows you to revert your migrations
    var commandConfig = CommandConfig.default()
    commandConfig.useFluentCommands()
    services.register(commandConfig)
   
    // Set up the hostname and port number and register this service
    let serverConfigure = NIOServerConfig.default(hostname: "localhost", port: 9090)
    services.register(serverConfigure)
    // Tells your application to use MemoryKeyedCache when asked for the KeyedCache service. The KeyedCache service is a key-value cache that backs sessions.
 //   config.prefer(MemoryKeyedCache.self, for: KeyedCache.self)
    
    
}
