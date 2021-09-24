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
    private let decoder = JSONDecoder()
    private let uuid = UUID()
    // TODO: - switchesCount remove later
    var switchesCount = 0
    var tapCount = 0
    var backTapCount = 0
    
    init() {
        self.lock = Lock()
        self.sockets = [:]
        self.logger = Logger(label: "WebSocketController")
    }
    
    func connect(_ ws: WebSocket) {
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
    
    private func onData(_ ws: WebSocket, _ data: Data) {
        self.logger.info("\(String(data: data, encoding: .utf8) ?? "Malformed data")")
        
        do {
            try handleData(data: data)
        } catch {
            print("Failed to handle data with error: \(error.localizedDescription)")
        }
    }
    
    private func handleData(data: Data) throws {
        let messageFromClient = try decoder.decode(TestMessageSinData.self, from: data)
        
        switch messageFromClient.type {
        case .response:
            try handleClientResponse(data: data)
        default:
            break
        }
    }
    
    private func handleClientResponse(data: Data) throws {
        let responseFromClient = try decoder.decode(ClientToServerResponse.self, from: data)
        let response = responseFromClient.response
        let command = response.command
        
        if response.success {
            print("Command \(command.commandType) with id: \((command.identification?.elementIdentification ?? command.identification?.staticText) ?? "") executed successfully")
        }
        
        
        if let error = response.error, let commandError = CommandExecutionError(rawValue: error) {
            print("Failed to execute command \(command.commandType) of id: \((command.identification?.elementIdentification ?? command.identification?.staticText) ?? "") with error: \(commandError.errorDescriprion)")
        }
    }
}

//element(using, value) {
//        return this.jsonWireCall({
//            method: 'POST',
//            relPath: `/element`,
//            data: {
//                using,
//                value
//            }
//        });
//    }
//
//    tapElement(element, timeout) {
//        return this.jsonWireCall({
//            method: 'POST',
//            relPath: `/touch/click`,
//            data: {
//                element,
//                timeout
//            }
//        });
//    }
//
//screenshot

extension WebSocketController {

    private func testFindElement() {
        
        guard let socket = sockets[uuid] else { return }
        
        let data = Details(using: .id, value: "start_button")
        let outcommingMessage = OutcomingMessage(method: .outcomingMessage, path: .element, data: data)
        
        send(message: OutcomingMessage, to: socket)
    }
}



