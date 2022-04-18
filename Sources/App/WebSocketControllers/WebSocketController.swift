/// Copyright (c) 2020 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Vapor
import Fluent

enum WebSocketSendOption {
    case id(String), socket(WebSocket)
}

class WebSocketController {
    let lock: Lock
    var sockets: [String: WebSocket]
    let db: Database
    let logger: Logger
    
    init(db: Database) {
        self.lock = Lock()
        self.sockets = [:]
        self.db = db
        self.logger = Logger(label: "WebSocketController")
    }
    
    func connect(_ ws: WebSocket, req: Request) async {
        // 1
        let uuid = UUID().uuidString
        self.lock.withLockVoid { [weak self] in
            guard let self = self else { return }
            self.sockets[uuid] = ws
        }
        
        ws.onBinary { [weak self] ws, buffer in
            guard let self = self,
                  let data = buffer.getData(at: buffer.readerIndex,
                                            length: buffer.readableBytes) else { return }
            print("this is on onBinary")
            await self.onData(ws, data, req)
        }
        
        ws.onText { [weak self] ws, text in
            guard let self = self, let data = text.data(using: .utf8) else { return }
            print("this is on onText")
            await self.onData(ws, data, req)
        }
        ws.onPing { ws in
            ws.sendPing()
        }
        // 4
        
        await send(message: QnAHandshake(id: uuid), to: .socket(ws))
    }
    
    func send<T: Codable>(message: T, to sendOption: WebSocketSendOption) async {
        logger.info("Sending \(T.self) to \(sendOption)")
        do {
            // 1
            let sockets: [WebSocket] = self.lock.withLock {
                switch sendOption {
                case .id(let id):
                    return [self.sockets[id]].compactMap { $0 }
                case .socket(let socket):
                    return [socket]
                }
            }
            
            // 2
            let encoder = JSONEncoder()
            let data = try encoder.encode(message)
            for socket in sockets {
                try await socket.send(raw: data, opcode: .binary)
            }
        } catch {
            logger.report(error: error)
        }
    }
    
    func onNewQuestion(_ ws: WebSocket,
                       _ message: NewQuestionMessage,
                       _ req: Request) async {
        
        let q = Question(content: message.content,
                         videoDuration: message.videoDuration,
                         fileID: message.fileID,
                         height: message.height,
                         width: message.width,
                         segmentCount: message.segmentCount,
                         createdAt: message.createdAt)

        do {
            try await db.withConnection {
                try await q.save(on: $0)
            }
            logger.info("Got a new question!")
        } catch {
            logger.report(error: error)
        }
       await send(message: VideoResponse(
            content: q.content,
            videoDuration: q.videoDuration,
            height: q.height,
            width: q.width,
            segmentCount: q.segmentCount,
            fileID: q.fileID,
            createdAt: q.createdAt
        ), to: .socket(ws))
    }
    
    func onData(_ ws: WebSocket, _ data: Data, _ req: Request) async {
        let currentUploadDirectory = getCurrentUploadDirectory(app: req.application, fileToWriteTo: "fileID")
        
        let uniqueID = UUID().uuidString
        let createFreshVideo = "\(uniqueID)"
        let createFreshPList = "\(uniqueID).plist"
        var iframePath = String()
        var progIndexPath = String()
        let createdPath = currentUploadDirectory.appending("/\(createFreshVideo)")
        let fileIO = req.application.fileio
//        let handle = try await fileIO.openFile(path: createdPath,
//                                               mode: .write,
//                                               flags: .allowFileCreation(posixMode: 0x744),
//                                               eventLoop: req.eventLoop).get()
//        var sequential = req.eventLoop.makeSucceededFuture(())
//
//        let promise = req.eventLoop.makePromise(of: HTTPStatus.self)
//        req.body.drain {
//            switch $0 {
//            case .buffer(let chunk):
//                sequential = sequential.flatMap {
//                    return fileIO.write(fileHandle: handle, buffer: chunk, eventLoop: req.eventLoop)
//                }
//                return sequential
//            case .error(let error):
//                promise.fail(error)
//                return req.eventLoop.makeSucceededFuture(())
//            case .end:
//                promise.succeed(.ok)
//                return req.eventLoop.makeSucceededFuture(())
//            }
//        }
//        let status = try await promise.futureResult.get()
//        defer { try? handle.close() }
//
        let decoder = JSONDecoder()
        do {
            // 1
            let newQuestionData = try decoder.decode(NewQuestionMessage.self, from: data)
            await self.onNewQuestion(ws,
                                     newQuestionData,
                                     req)
        } catch {
            logger.report(error: error)
        }
    }
}
