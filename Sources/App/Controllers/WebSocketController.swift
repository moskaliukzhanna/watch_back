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
    var sockets: [UUID: WebSocket]
    let logger: Logger
    
    init() {
        self.lock = Lock()
        self.sockets = [:]
        self.logger = Logger(label: "WebSocketController")
    }
    
    func connect(_ ws: WebSocket) {
        let uuid = UUID()
        self.lock.withLockVoid {
            self.sockets[uuid] = ws
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
        self.send(message: TestMessageHandshake(id: uuid), to: .socket(ws))
        
    }
    
    func send<T: Codable>(message: T, to sendOption: WebSocketSendOption) {
        logger.info("Sending \(T.self) to \(sendOption)")
        do {
          let sockets: [WebSocket] = self.lock.withLock {
            switch sendOption {
            case .id(let id):
              return [self.sockets[id]].compactMap { $0 }
            case .socket(let socket):
              return [socket]
            case .all:
              return self.sockets.values.map { $0 }
            case .ids(let ids):
              return self.sockets.filter { key, _ in ids.contains(key) }.map { $1 }
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
    
    func onData(_ ws: WebSocket, _ data: Data) {
        self.logger.info("\(String(data: data, encoding: .utf8) ?? "Malformed data")")
    }
}
