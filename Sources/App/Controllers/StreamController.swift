import Fluent
import Vapor
import NIOCore
import Leaf

struct StreamController {
    static let partSize = 4096
    let logger = Logger(label: "StreamController")
    
    func index(req: Request) async throws -> [StreamModel] {
        try await StreamModel.query(on: req.db).all()
    }
    
    func newHandler(_ req: Request) async throws -> Response {
        let badResponse = Response(status: .forbidden, version: .http1_0, headers: HTTPHeaders(), body: .empty)
        
        guard let fileID = req.parameters.get("fileID") else {
            return try await req.eventLoop.future(badResponse).get()
        }
        guard let fileName = req.parameters.get("fileName") else {
            return try await req.eventLoop.future(badResponse).get()
        }
        
        let fileManager = FileManager.default
        let currentPathDirectory = fileManager.currentDirectoryPath
        let filePath = currentPathDirectory.appending("/uploads/\(fileID)/\(fileName)")
        // let filePath = app.directory.workingDirectory + "uploads/" + fileName
        
        //fileName
        guard let file = File(filePath: filePath) else {
            return try await req.eventLoop.future(badResponse).get()
        }
        print(filePath)
       // req.fileio.streamFile(at: <#T##String#>)
        return try await req.fileio.streamFile(at: filePath).encodeResponse(for: req)
//        { biteBuffer in
//            let body = Response.Body(buffer: biteBuffer)
//
//            let response = Response(status: .ok, headers: HTTPHeaders(), body: body)
//
//            file.delete()
//
//            return response
//        }.get()
//
       // return te
    }
    
    func fileHandler(_ req: Request) async throws -> View {
        guard let id = req.parameters.get("id") else { fatalError("fileID failed to add to url")}
        return try await req.view.render("hello",  WelcomeContext(url: id,
                                                                 height: "812",
                                                                 width: "375"))
    }
   
    func indexHandler(_ req: Request) async throws -> View {
      // 5
//        let resourcesDirectory = req.application.directory.resourcesDirectory
//        let executableURL = resourcesDirectory + "/MediaFileSegmenter/mediafilesegmenter"
//        print(executableURL)
//        guard let fileID = req.parameters.get("fileID") else { fatalError("fileID failed to add to url")}
//        guard let height = req.parameters.get("height") else { fatalError("height failed to add to url")}
//        guard let width = req.parameters.get("width") else { fatalError("width failed to add to url")}
        let fileManager = FileManager.default
        let currentPathDirectory = fileManager.currentDirectoryPath
        let currentUploadDirectory = getCurrentUploadDirectory(app: req.application, fileToWriteTo: "fileID")
        let htmlFilePath = "/uploads/\("fileID")/\("fileID").html"
        currentUploadDirectory.appending("/\("fileID").html")
        //let htmlFilePath = "https://d2zihajmogu5jn.cloudfront.net/bipbop-advanced/bipbop_16x9_variant.m3u8"
        //let htmlFilePath = "http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8"
       // let htmlFilePath = currentPathDirectory.appending("/uploads/\("fileID")/\("fileID").m3u8")
        print(htmlFilePath)
//        return try await req.view.render("index",
//                                         WelcomeContext(url: htmlFilePath,
//                                                        height: height,
        //                                                        width: width))
        return try await req.view.render("index",
                                         WelcomeContext(url: htmlFilePath,
                                                        height: "812",
                                                        width: "375"))
    }
    
    func getTestVideo(_ req: Request) async throws -> String {
        let fileManager = FileManager.default
        let currentPathDirectory = fileManager.currentDirectoryPath
        let htmlFilePath = currentPathDirectory.appending("/uploads/poorMans.html")
        let poorMans = Self.poorMans()
        if !fileManager.fileExists(atPath: htmlFilePath) {
            let htmlData = poorMans.data(using: .utf8)
            let isEnabled = fileManager.createFile(atPath: htmlFilePath, contents: htmlData)
            if isEnabled {
                print("yay")
            } else {
                fatalError("failed to create file")
            }
        }
        return poorMans
        ///Use this for the normal code 
//        guard let fileID = req.parameters.get("fileID") else { fatalError("fileID failed to add to url")}
//        let fileManager = FileManager.default
//        let currentPathDirectory = fileManager.currentDirectoryPath
//        let htmlFilePath = currentPathDirectory.appending("/uploads/\(fileID)/\(fileID).html")
//        let url = URL(fileURLWithPath: htmlFilePath)
//        /// let data = Data(contentsOf: url, options: .mappedIfSafe)
//        let data = try Data(contentsOf: url)
//        guard let htmlBody = String(data: data, encoding: .utf8) else { fatalError("htmlBody failed to become a string")}
////        let body: Response.Body = .init(string: htmlBody)
////        let response = try await Response(status: .ok, version: .http2, body: body).encodeResponse(for: req)
//        //let response = Response.encodeResponse(res).(req)
//        //return response
//        return htmlBody
    }
    
//    func getTestVideo(_ req: Request) throws -> Response {
//        // add controller code here
//        // to determine which image is returned
//        let inputPath = fileName(with: req.headers)
//       // let thisStreamModel = try await getStreamModel(id: inputPath, req: req)
//        //let thisModelID = thisStreamModel?.fileID
////
////        let currentUploadDirectory = getCurrentUploadDirectory(app: req.application, fileToWriteTo: thisModelID!)
//
//        //let filePath = "\(currentUploadDirectory)/iframe_index.m3u8"
//        //let fileUrl = URL(fileURLWithPath: filePath)
//
//        do {
//            let data = try Data(contentsOf: fileUrl)
//            let body = req.body
//            let header = req.headers
//           // "m3u8": HTTPMediaType(type: "application", subType: "x-mpegURL")
//            // makeResponse(body: LosslessHTTPBodyRepresentable, as: MediaType)
//            let response: Response = Response(status: .ok, version: .http2, headers: .init([("m3u8", "x-mpegURL"),
//                                                                                           ]), body: .init(data: data))
//            return response
//        } catch {
//            let response: Response = .ok
//            return response
//        }
//    }
    
    func getStreamModel(id: String, req: Request) async throws -> StreamModel? {
        try await StreamModel.query(on: req.db)
            .filter(\.$fileID == id)
            .first()
    }
    
    func getStreamUrlPath(id: String, req: Request) async throws -> String? {
        try await getStreamModel(id: id, req: req)?
            .filePath(for: req.application)
    }
    
    func getOne(req: Request) async throws -> StreamModel {
        guard let streamModel = try await StreamModel.query(on: req.db).first() else {
            throw Abort(.notAcceptable)
        }
        return streamModel
    }
    
    /// Streaming download comes with Vapor “out of the box”.
    /// Call `req.fileio.streamFile` with a path and Vapor will generate a suitable Response.
    func downloadOne(req: Request) async throws -> Response {
        let getOne = try await getOne(req: req)
        let fileName = getOne.fileName
        return req.fileio.streamFile(at: fileName, chunkSize: 4096, mediaType: .any) { result in
            switch result {
            case .failure(let error):
                debugPrint(error.localizedDescription)
            case .success(_):
                debugPrint("Success")
            }
        }
    }
    
    func uploading(req: Request) async throws -> HTTPStatus {
        print("I am here")
        let currentUploadDirectory = getCurrentUploadDirectory(app: req.application, fileToWriteTo: "fileID")
        let uniqueID = UUID().uuidString
        let createFreshVideo = "\(uniqueID).mp4"
        let createFreshPList = "\(uniqueID).plist"
        var iframePath = String()
        var progIndexPath = String()
        let createdPath = currentUploadDirectory.appending("/\(createFreshVideo)")
        let createdPList = currentUploadDirectory.appending("/\(createFreshPList)")
        //let file = File(data: "", filename: createdPath)
        let fileIO = req.application.fileio
        let handle = try await fileIO.openFile(path: createdPath,
                                               mode: .write,
                                               flags: .allowFileCreation(posixMode: 0x744),
                                               eventLoop: req.eventLoop).get()
        
        var sequential = req.eventLoop.makeSucceededFuture(())
        
        let promise = req.eventLoop.makePromise(of: HTTPStatus.self)
        
        req.body.drain {
            switch $0 {
            case .buffer(let chunk):
                sequential = sequential.flatMap {
                    return fileIO.write(fileHandle: handle, buffer: chunk, eventLoop: req.eventLoop)
                }
                return sequential
            case .error(let error):
                promise.fail(error)
                return req.eventLoop.makeSucceededFuture(())
            case .end:
                promise.succeed(.ok)
                return req.eventLoop.makeSucceededFuture(())
            }
        }
        
        let status = try await promise.futureResult.get()
        //try? handle.close()
        defer { try? handle.close() }
        return status
    }
    
    func upload(req: Request) async throws -> HTTPStatus {
        let fileName = fileName(with: req.headers)
        let duration = duration(with: req.headers)
        let count = count(with: req.headers)
        let height = height(with: req.headers)
        let width = width(with: req.headers)
        
        let fileManager = FileManager.default
        let currentUploadDirectory = makeCurrentUploadDirectory(app: req.application, fileToWriteTo: fileName)
        let videoFilePath = currentUploadDirectory + "/\(fileName).m3u8"
        let htmlFilePath = currentUploadDirectory.appending("/\(fileName).html")
        if !fileManager.fileExists(atPath: htmlFilePath) {
            let staticHTML = Self.createStaticHTMLFileForVideo(with: videoFilePath, height: height, width: width)
            let htmlData = staticHTML.data(using: .utf8)
            let isEnabled = fileManager.createFile(atPath: htmlFilePath, contents: htmlData)
            guard isEnabled else { fatalError("failed to create file") }
        }
        let uniqueID = UUID().uuidString
        let createFreshVideo = "\(uniqueID).mp4"
        let createFreshPList = "\(uniqueID).plist"
        var iframePath = String()
        var progIndexPath = String()
        let createdPath = currentUploadDirectory.appending("/\(createFreshVideo)")
        let createdPList = currentUploadDirectory.appending("/\(createFreshPList)")
        let fileIO = req.application.fileio
        let handle = try await fileIO.openFile(path: createdPath,
                                               mode: .write,
                                               flags: .allowFileCreation(posixMode: 0x744),
                                               eventLoop: req.eventLoop).get()

        var sequential = req.eventLoop.makeSucceededFuture(())
        
        let promise = req.eventLoop.makePromise(of: HTTPStatus.self)
        
        req.body.drain {
            switch $0 {
            case .buffer(let chunk):
                sequential = sequential.flatMap {
                    return fileIO.write(fileHandle: handle, buffer: chunk, eventLoop: req.eventLoop)
                }
                return sequential
            case .error(let error):
                promise.fail(error)
                return req.eventLoop.makeSucceededFuture(())
            case .end:
                promise.succeed(.ok)
                return req.eventLoop.makeSucceededFuture(())
            }
        }
        
        let status = try await promise.futureResult.get()
        try? handle.close()
        
        switch status {
        case .ok:
            let resourcesDirectory = req.application.directory.resourcesDirectory
            let executableURL = resourcesDirectory + "MediaFileSegmenter/mediafilesegmenter"
            let _ = try safeShell(durationOfVideo: duration, videoFile: createdPath, fileOutputToWriteTo: currentUploadDirectory, executableURL: executableURL)
            iframePath = currentUploadDirectory + "/iframe_index.m3u8"
            progIndexPath = currentUploadDirectory + "/prog_index.m3u8"
        default:
            break
        }
  
        if let data = FileManager.default.contents(atPath: videoFilePath) {
            guard let videoStringPath = String(data: data, encoding: .utf8) else { fatalError("not a string") }
            let appendSegmentInfo = videoStringPath + Self.makeAppendSegmentInfo(segmentCount: count, duration: duration)
            let newData = appendSegmentInfo.data(using: .utf8)
            let tempFile = NSTemporaryDirectory() + "/\(fileName).m3u8"
            let canWrite = FileManager.default.createFile(atPath: tempFile, contents: newData)
            guard canWrite else { fatalError("can't write to this")}
            let url = try FileManager.default.replaceItemAt(URL(fileURLWithPath: videoFilePath), withItemAt: URL(fileURLWithPath: tempFile), backupItemName: nil, options: .usingNewMetadataOnly)
            guard url!.relativePath == videoFilePath else { fatalError("they arent the same file") }
        } else {
            let fileContet = Self.makeFile()
            let appendSegmentInfo = fileContet + Self.makeAppendSegmentInfo(segmentCount: count, duration: duration)
            let data = appendSegmentInfo.data(using: .utf8)
            let canWrite = FileManager.default.createFile(atPath: videoFilePath, contents: data)
            guard canWrite else { fatalError("can't write to this") }
        }
        ///Clean up
        try FileManager.default.removeItem(atPath: createdPList)
        try FileManager.default.removeItem(atPath: createdPath)
        try FileManager.default.removeItem(atPath: iframePath)
        try FileManager.default.removeItem(atPath: progIndexPath)
        return status
    }
    
    
    func safeShell(durationOfVideo: String, videoFile: String, fileOutputToWriteTo fileOutput: String, executableURL: String) throws {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-t", durationOfVideo, videoFile, "-f", fileOutput]
        task.executableURL = URL(fileURLWithPath: executableURL) //<--updated
        task.qualityOfService = .default
        
        try task.run() //<--updated
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let _ = String(data: data, encoding: .utf8)!
        //dump(output)
//        return output
    }
    
    func fileUpload(req: Request) async throws -> HTTPStatus {
        
        return .ok
    }
    
    private static func makeAppendSegmentInfo(segmentCount: String, duration: String) -> String {
        return "\n#EXTINF:\(duration),\t\n"
        + "fileSequence\(segmentCount).ts"

    }
    
    private static func makeFile() -> String {
        return "#EXTM3U\n"
        + "#EXT-X-TARGETDURATION:10\n"
        + "#EXT-X-VERSION:8\n"
        + "#EXT-X-PLAYLIST-TYPE:EVENT\n"
        + "#EXT-X-MEDIA-SEQUENCE:0"
    }

    static func getFileSize(file: URL) throws -> (Int, Int) {
        do {
            let resources = try file.resourceValues(forKeys:[.totalFileAllocatedSizeKey])
            guard let fileAllocatedSize = resources.fileAllocatedSize else {
                throw Abort(.created)
            }
            let blocksInDouble = ceil(Double(fileAllocatedSize) / Double(Self.partSize))
            let blocks = Int(blocksInDouble)
            return (fileAllocatedSize, blocks)
        } catch {
            throw Abort(.conflict)
        }
    }
    
    func getPoorMansAndCreate() async throws -> String {
        let fileManager = FileManager.default
        let currentPathDirectory = fileManager.currentDirectoryPath
        let htmlFilePath = currentPathDirectory.appending("/uploads/poorMans.html")
        let poorMans = Self.poorMans()
        if !fileManager.fileExists(atPath: htmlFilePath) {
            let htmlData = poorMans.data(using: .utf8)
            let isEnabled = fileManager.createFile(atPath: htmlFilePath, contents: htmlData)
            if isEnabled {
                print("yay")
            } else {
                fatalError("failed to create file")
            }
        }
        return poorMans
    }
    
    static func poorMans() -> String {
       return
            """
            <html>
                <head>
                    <title>HTTP Live Streaming Example</title>
                </head>
                <body>
                    <video src="http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8" height="300" width="400">
                    </video>
                </body>
            </html>
            """
    }
    
    static func createStaticHTMLFileForVideo(with id: String, height: String, width: String) -> String {
       return
            """
            <html>
                <head>
                    <title>HTTP Live Streaming Example</title>
                </head>
                <body>
                    <video src=\"\(id)\" height=\"\(height)\" width=\"\(width)\">
                    </video>
                </body>
            </html>
            """
///        let url = "http://127.0.0.1:8080/uploads/\(id)/\(id).m3u8
///        let that = """
///                    <html>
///                        <head>
///                            <title>HTTP Live Streaming Example</title>
///                        </head>
///                        <body>
///                            <video src="\(url)" height="\(height)" width="\(width)">
///                            </video>
///                        </body>
///                     </html>
///                   """
    }
}

struct WelcomeContext: Encodable {
    var url: String
    var height: String
    var width: String
}

struct CompletedPart: Content {
    let eTag: ETag
    let partNumber: Int32
}

struct ETag: Content {
    let file: URL
    let uploadID: String
    let part: Int
    let data: Data
    let totalSize: Int
}

struct NewFile: Content {
    
   // var fileID: String
    var iframeData: Data
    var data: Data
//
//    func fileID() throws -> String {
//        guard let lastOccuranceOfPeriodIndex = fileName.lastIndex(where: {$0 == "."}) else { throw Abort(.notAcceptable) }
//        let fileNameSubString = fileName[fileName.startIndex..<lastOccuranceOfPeriodIndex]
//        let fileID = String(fileNameSubString)
//        return fileID
//    }
}
