import Fluent
import FluentPostgresDriver
import Vapor
import NIOSSL
import Leaf

// configures your application
public func configure(_ app: Application) throws {
    
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
   
//    let certPath = "/Users/civilgisticslabs/Downloads/VaporUploads-main copy/data/certbot/conf/cert.pem"
//    let keyPath = "/Users/civilgisticslabs/Downloads/VaporUploads-main copy/data/certbot/conf/key.pem"
//    let certs = try! NIOSSLCertificate.fromPEMFile(certPath)
//        .map { NIOSSLCertificateSource.certificate($0) }
//    let tls = TLSConfiguration.makeServerConfiguration(certificateChain: certs, privateKey: .file(keyPath))
    let logger = Logger(label: "configure")
    let configuredDir = configureUploadDirectory(for: app)

    configuredDir.whenFailure { err in
        logger.error("Could not create uploads directory \(err.localizedDescription)")
    }
    configuredDir.whenSuccess { dirPath in
        logger.info("created upload directory at \(dirPath)")
    }
 
    app.http.server.configuration = .init(hostname: "127.0.0.1",
                                             port: 8060,
                                             backlog: 256,
                                             reuseAddress: true,
                                             tcpNoDelay: true,
                                             responseCompression: .enabled,
                                             requestDecompression: .enabled,
                                             supportPipelining: true,
                                          supportVersions: Set<HTTPVersionMajor>([.one]),
                                            // tlsConfiguration: nil,
                                             serverName: nil,
                                             logger: logger)

    app.views.use(.leaf)
    
    // uncomment to serve files from /Public folder

    let databaseName: String
    let databasePort: Int
    // 1
    if (app.environment == .testing) {
        databaseName = "vapor-test"
        databasePort = 5433
    } else {
        databaseName = "vapor_database"
        databasePort = 5432
    }
    
    app.databases.use(.postgres(
      hostname: Environment.get("DATABASE_HOST")
        ?? "localhost",
      port: databasePort,
      username: Environment.get("DATABASE_USERNAME")
        ?? "vapor_username",
      password: Environment.get("DATABASE_PASSWORD")
        ?? "vapor_password",
      database: Environment.get("DATABASE_NAME")
        ?? databaseName
    ), as: .psql)
    
//    if let port = Environment.get("PORT").flatMap(Int.init) {
//        app.http.server.configuration.port = port
//    }
//
    app.migrations.add(CreateCollect())
    app.migrations.add(CreateStream())
    app.migrations.add(CreateQuestion())
    try app.autoMigrate().wait()
    // register routes
    try routes(app)
}
