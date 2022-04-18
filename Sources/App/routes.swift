import Fluent
import Vapor

func routes(_ app: Application) throws {
    
    app.get("vaportest") { req in
        return "good bye, vapor!"
    }
    
    app.get("hello") { req in
        return "Hello, vapor!"
    }
    // MARK: /collect
    let collectFileController = CollectFileController()
    app.get("collect", use: collectFileController.index)
    
    /// Using `body: .collect` we can load the request into memory.
    /// This is easier than streaming at the expense of using much more system memory.
    app.on(.POST, "collect",
          // 27_981_973
           body: .collect(maxSize: 40_000_000),
           use: collectFileController.upload)
    app.on(.GET, "collect",
           use: collectFileController.index)
    // MARK: /stream
    app.webSocket("") { req, ws in
        print("I am here")
         ws.onBinary { ws, byteBuffer in
             print("I am here")
        }
    }
//
    let uploadController = StreamController()
    /// using `body: .stream` we can get chunks of data from the client, keeping memory use low.
    /// this is stream/fileID/segmentCount/videoDuration/height/width
    /// example is 127.0.0.1:8080/stream/123e4567-e89b-12d3-a456-426614174000/34/10/400/300
    /// they are used to create the static .m3u8 files
    
    app.on(.POST,
           "stream",
        body: .stream,
        use: uploadController.upload)
////    app.on(.POST, "streaming",
////           body: .stream,
////        use: uploadController.uploading)
//   // app.on(.GET, "stream", use: uploadController.index)
//    //app.on(.GET, "stream", ":fileID", use: uploadController.getTestVideo)
//    app.on(.GET, "stream", use: uploadController.getTestVideo)
//   // app.on(.GET, "stream", ":fileID", use: uploadController.getOne)
//    app.on(.GET, "stream", "all", use: uploadController.index)
   // app.on(.GET, "getPoorMans", ":fileID", use: uploadController.getPoorMansAndCreate)
    app.on(.GET, "leaf", use: uploadController.indexHandler)
    app.on(.GET, "hello", ":id", use: uploadController.fileHandler)
    app.on(.POST,
           "streaming",
           body: .stream,
           use: uploadController.uploading)

    //app.on(.GET, "stream", "single", use: uploadController.)
    app.on(.GET, ":fileID", ":fileName", use: uploadController.newHandler)
    
    let webSocketController = WebSocketController(db: app.db)
    try app.register(collection: QuestionsController(wsController: webSocketController))
    
}

final class File {
    
    private let fileManager = FileManager.default
    private let url: URL
    
    init?(filePath: String) {
        guard let url = URL(string: "file:" + filePath) else {
            return nil
        }
        
        self.url = url
    }
    
    func delete() {
        do {
            try fileManager.removeItem(at: url)
        } catch {
        }
    }
    
}
