import Vapor

// MARK: Helpers for naming files

/// Intended entry point for naming files
/// - Parameter headers: Source `HTTPHeaders`
/// - Returns: `String` with best guess file name.
func fileName(with headers: HTTPHeaders) -> String {
    let fileNameHeader = headers["File-Name"]
    if let inferredName = fileNameHeader.first {
        return "\(inferredName)"
    }
    
    return UUID().uuidString
}

func count(with headers: HTTPHeaders) -> String {
    let countHeader = headers["Count"]
    if let countHeader = countHeader.first {
        return countHeader
    }
    
    return "fatalError(failed to set the duration in the header feilds)"
}

func duration(with headers: HTTPHeaders) -> String {
    let durationHeader = headers["Duration"]
    if let inferredDuration = durationHeader.first {
        return inferredDuration
    }
    
    return "fatalError(failed to set the duration in the header feilds)"
}

func height(with headers: HTTPHeaders) -> String {
    let heightHeader = headers["Height"]
    if let heightHeader = heightHeader.first {
        return heightHeader
    }
    
    return "fatalError(failed to set the duration in the header feilds)"
}
func width(with headers: HTTPHeaders) -> String {
    let widthHeader = headers["Width"]
    if let widthHeader = widthHeader.first {
        return widthHeader
    }
    
    return "fatalError(failed to set the duration in the header feilds)"
}
func iFrameIndex(with headers: HTTPHeaders) -> String {
    let iFrameIndexHeader = headers["iframe"]
    if let iFrameIndex = iFrameIndexHeader.first {
        return iFrameIndex
    }
    
    return "fatalError(failed to set the iframe in the header feilds)"
}

/// Parse the header’s Content-Type to determine the file extension
/// - Parameter headers: source `HTTPHeaders`
/// - Returns: `String` guess at appropriate file extension
func fileExtension(for headers: HTTPHeaders) -> String {
    var fileExtension = "tmp"
    if let contentType = headers.contentType {
        switch contentType {
        case .jpeg:
            fileExtension = "jpg"
        case .mp3:
            fileExtension = "mp3"
        case .init(type: "video", subType: "mp4"):
            fileExtension = "mp4"
        default:
            fileExtension = "bits"
        }
    }
    return fileExtension
}

/// Creates the upload directory as part of the working directory
/// - Parameters:
///   - directoryName: sub-directory name
///   - app: Application
/// - Returns: name of the directory
func configureUploadDirectory(named directoryName: String = "uploads/", for app: Application) -> EventLoopFuture<String> {
    let createdDirectory = app.eventLoopGroup.next().makePromise(of: String.self)
    var uploadDirectoryName = app.directory.publicDirectory
    if directoryName.last != "/" {
        uploadDirectoryName += "/"
    }
    uploadDirectoryName += directoryName
    do {
        try FileManager.default.createDirectory(atPath: uploadDirectoryName,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
        createdDirectory.succeed(uploadDirectoryName)
    } catch {
        createdDirectory.fail(FileError.couldNotSave)
    }
    return createdDirectory.futureResult
}

func getCurrentUploadDirectory(app: Application, fileToWriteTo: String) -> String {
    let uploadDirectoryName = app.directory.publicDirectory
    let directoryName = "uploads/\(fileToWriteTo)"
    let currentUploadFilePath = uploadDirectoryName + directoryName
    return currentUploadFilePath
}

func makeCurrentUploadDirectory(app: Application, fileToWriteTo: String) -> String {
    let uploadDirectoryName = app.directory.publicDirectory
    let directoryName = "uploads/\(fileToWriteTo)"
    let currentUploadFilePath = uploadDirectoryName + directoryName
    if !FileManager.default.fileExists(atPath: currentUploadFilePath) {
        do {
            try FileManager.default.createDirectory(atPath: currentUploadFilePath,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
            // createdDirectory.succeed(uploadDirectoryName)
        } catch {
            debugPrint(error.localizedDescription)
        }
    }
    return currentUploadFilePath
}
