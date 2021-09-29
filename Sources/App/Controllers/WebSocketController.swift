//
//  WebSocketController.swift
//  
//
//  Created by Zhanna Moskaliuk on 01.06.2021.
//

import Foundation
import Vapor

enum WebSocketSendOption {
    case id(UUID), socket(WebSocket)
    case all, ids([UUID])
}

class WebSocketController {
    let lock: Lock
    //    var sockets: [UUID: WebSocket]
    var sockets: [WebSocket]
    let logger: Logger
    private let decoder = JSONDecoder()
    private let uuid = UUID()
    // TODO: - switchesCount remove later
    var switchesCount = 0
    var tapCount = 0
    var backTapCount = 0
    
    init() {
        self.lock = Lock()
        //        self.sockets = [:]
        self.sockets = []
        self.logger = Logger(label: "WebSocketController")
    }
    
    func connect(_ ws: WebSocket) {
        self.lock.withLockVoid {
            //            self.sockets[uuid] = ws
            self.sockets.append(ws)
        }
        ws.onBinary { [weak self] ws, buffer in
            guard let self = self,
                  let data = buffer.getData(
                    at: buffer.readerIndex, length: buffer.readableBytes) else {
                return
            }
            
            self.onData(ws, data)
        }
        ws.onText { [weak self] ws, text in
            guard let self = self,
                  let data = text.data(using: .utf8) else {
                return
            }
            
            self.onData(ws, data)
        }
        let initialMessage = OutcomingMessage(method: .outcomingMessage, path: .initial, data: nil)
        self.send(message: initialMessage, to: .socket(ws))
        self.switchesCount = 0
        
        // send test commands
        testFindElement()
        
        tapCount = 0
        backTapCount = 0
    }
    
    func send<T: Codable>(message: T, to sendOption: WebSocketSendOption) {
        logger.info("Sending \(T.self) to \(sendOption)")
        do {
            let sockets: [WebSocket] = self.lock.withLock {
                switch sendOption {
                //                case .id(let id):
                //                    return [self.sockets[id]].compactMap { $0 }
                //                break
                case .socket(let socket):
                    return [socket]
                //                case .all:
                //                    return self.sockets.values.map { $0 }
                //                break
                //                case .ids(let ids):
                //                    return self.sockets.filter { key, _ in ids.contains(key) }.map { $1 }
                //                break
                default:
                    return self.sockets
                    break
                }
            }
            let encoder = JSONEncoder()
            let data = try encoder.encode(message)
            
            sockets.forEach {
                $0.send(raw: data, opcode: .binary)
            }
        } catch {
            logger.report(error: error)
        }
    }
    
    private func onData(_ ws: WebSocket, _ data: Data) {
        self.logger.info("\(String(data: data, encoding: .utf8) ?? "Malformed data")")
        
        handleData(data: data)
    }
    
    private func handleData(data: Data) {
        do {
            let responseFromClient = try decoder.decode(ExecutionResponse.self, from: data)
            
            let status = responseFromClient.status
            let info = responseFromClient.detail
            
            print("Command executed with status \(status) : \(info)")
            if let socket = sockets.first {
                let shutdownMessage = OutcomingMessage(method: .outcomingMessage, path: .shutdown)
                self.send(message: shutdownMessage, to: .socket(socket))
            }
        } catch {
            print("Failed to decode client's response with error: \(error.localizedDescription)")
        }
    }
}
    extension WebSocketController {
        
        private func testFindElement() {
            
            guard let socket = sockets.first else { return }
            
            let data = Details(using: .id, value: "goToColorButton")
            let outcommingMessage = OutcomingMessage(method: .outcomingMessage, path: .element, data: data)
            
            send(message: outcommingMessage, to:  .socket(socket))
        }
    }



