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
    var switchesCount = 0
    var screenshotsCount = 0
    
    init() {
        self.lock = Lock()
        self.sockets = [:]
        self.logger = Logger(label: "WebSocketController")
    }
    
    func connect(_ ws: WebSocket) {
        //        uuid = UUID()
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
        
        // send test commands
        self.staticTextExists()
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
            // DELETE LATER
            // ONLY FOR TESTING
            // run test commands when previous one is finished
            
            switch command.commandType {
            case .staticTextExists:
                sendIsEnabled()
            case .isEnabled:
                tapAndWait()
            case .tapAndWait:
                makeTestScreenshot()
            case .makesreenshot:
                if switchesCount < 4 {
                    sendSwitch()
                } else {
                    sendDisconnect()
                }
            case .switchValue:
                // switch back a few times
                if switchesCount < 4 {
                    sendSwitch()
                } else {
                    tapBackButton()
                    // make screenshot after that
                    makeTestScreenshot()
                }
            default:
                break
            }
        }
        if let error = response.error, let commandError = CommandExecutionError(rawValue: error) {
            print("Failed to execute command \(command.commandType) of id: \((command.identification?.elementIdentification ?? command.identification?.staticText) ?? "") with error: \(commandError.errorDescriprion)")
        }
    }
    
    private func sendTestTap() {
        // tap on "Start" button, it should take us to the next screen
        guard let socket = sockets[uuid] else { return }
        let command = Command(commandType: .tap, identificationType: .accessibilityId, identification: ElementIdentification(elementIdentification: "start_button"))
        self.send(message: ServerToClientMessage(id: uuid, command: command, createdAt: Date()), to: .socket(socket))
    }
    
    private func makeTestScreenshot() {
        screenshotsCount += 1
        guard let socket = sockets[uuid] else { return }
        // Make screenshot on the next screen
        let command = Command(commandType: .makesreenshot)
        self.send(message: ServerToClientMessage(id: uuid, command: command, createdAt: Date()), to: .socket(socket))
    }
    
    private func tapAndWait() {
        guard let socket = sockets[uuid] else { return }
        let command = Command(commandType: .tapAndWait, identificationType: .accessibilityId, identification: ElementIdentification(elementIdentification: "start_button"), waitTimeout: 3)
        self.send(message: ServerToClientMessage(id: uuid, command: command, createdAt: Date()), to: .socket(socket))
    }
    
    private func sendIsEnabled() {
        guard let socket = sockets[uuid] else { return }
        let command = Command(commandType: .isEnabled, identificationType: .accessibilityId, identification: ElementIdentification(elementIdentification: "start_button"))
        self.send(message: ServerToClientMessage(id: uuid, command: command, createdAt: Date()), to: .socket(socket))
    }
    
    private func staticTextExists() {
        guard let socket = sockets[uuid] else { return }
        let command = Command(commandType: .staticTextExists, identificationType: .staticText, identification: ElementIdentification(staticText: "Hello there!"))
        self.send(message: ServerToClientMessage(id: uuid, command: command, createdAt: Date()), to: .socket(socket))
    }
    
    private func sendSwitch() {
        switchesCount += 1
        guard let socket = sockets[uuid] else { return }
        let command = Command(commandType: .switchValue, identificationType: .accessibilityId, identification: ElementIdentification(elementIdentification: "catSwitch"))
        self.send(message: ServerToClientMessage(id: uuid, command: command, createdAt: Date()), to: .socket(socket))
    }
    
    private func tapBackButton() {
        // now go back to the main screen
        guard let socket = sockets[uuid] else { return }
        let command = Command(commandType: .tapAndWait, identificationType: .accessibilityId, identification: ElementIdentification(elementIdentification: "BackButton"), waitTimeout: 3)
        self.send(message: ServerToClientMessage(id: uuid, command: command, createdAt: Date()), to: .socket(socket))
    }
    
    private func swipeLeft() {
        guard let socket = sockets[uuid] else { return }
        let command = Command(commandType: .swipeLeft, identificationType: .accessibilityId, identification: ElementIdentification(elementIdentification: "swipe_group"), waitTimeout: 0)
        self.send(message: ServerToClientMessage(id: uuid, command: command, createdAt: Date()), to: .socket(socket))
    }
    
    private func sendDisconnect() {
        guard let socket = sockets[uuid] else { return }
        // send shutdown message to the client
        self.send(message: ShutdownMessage(id: uuid, sentAt: Date()), to: .socket(socket))
    }
}
