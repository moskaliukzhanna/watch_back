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
        self.tapAndWait(id: "table_button")
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
            // DELETE LATER
            // ONLY FOR TESTING
            // run test commands when previous one is finished
            switch command.commandType {
//            case .staticTextExists:
//                tapAndWait(id: "second_button")
            case .tapAndWait:
                if tapCount < 2 {
                scrollTableDownForStaticTextCell(text: "23.11.2019.")
                tapCount += 1
                } else {
                    tapBackButton()
                    backTapCount += 1
                }
            case .tableStaticTextCellScrollDown:
                scrollTableUpForStaticTextCell(text: "23.10.2020.")
            case .tableStaticTextCellScrollUp:
                tapAndWait(text: "23.10.2020.")
                tapCount += 1
            case .tapBackButton:
                if backTapCount < 2 {
                tapBackButton()
                backTapCount += 1
                }
//                sendIsEnabled()
//            case .isEnabled:
//                tapAndWait(id: "start_button")
//            case .tapAndWait:
//                makeTestElementScreenshot(id: "catImage")
//            case .makesreenshot:
//                if switchesCount < 4 {
//                    sendSwitch()
//                } else {
//                    sendDisconnect()
//                }
//            case .switchValue:
//                // switch back a few times
//                if switchesCount < 4 {
//                    sendSwitch()
//                } else {
//                    tapBackButton()
//                }
//            case .elementSreenshot:
//                sendDisconnect()
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
        guard let socket = sockets[uuid] else { return }
        // Make screenshot on the next screen
        let command = Command(commandType: .makesreenshot, waitTimeout: 2)
        self.send(message: ServerToClientMessage(id: uuid, command: command, createdAt: Date()), to: .socket(socket))
    }
    
    private func makeTestElementScreenshot(id: String) {
        guard let socket = sockets[uuid] else { return }
        // Make screenshot on the next screen
        let command = Command(commandType: .elementSreenshot, identificationType: .accessibilityId, identification: ElementIdentification(elementIdentification: id), waitTimeout: 0)
        self.send(message: ServerToClientMessage(id: uuid, command: command, createdAt: Date()), to: .socket(socket))
    }
    
    private func tapAndWait(id: String) {
        guard let socket = sockets[uuid] else { return }
        let command = Command(commandType: .tapAndWait, identificationType: .accessibilityId, identification: ElementIdentification(elementIdentification: id), waitTimeout: 3)
        self.send(message: ServerToClientMessage(id: uuid, command: command, createdAt: Date()), to: .socket(socket))
    }
    
    private func tapAndWait(text: String) {
        guard let socket = sockets[uuid] else { return }
        let command = Command(commandType: .tapAndWait, identificationType: .staticText, identification: ElementIdentification(staticText: text), waitTimeout: 0)
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
        let command = Command(commandType: .tapBackButton, identificationType: .accessibilityId, identification: ElementIdentification(elementIdentification: "BackButton"), waitTimeout: 3)
        self.send(message: ServerToClientMessage(id: uuid, command: command, createdAt: Date()), to: .socket(socket))
    }
    
//    private func swipeLeft() {
//        guard let socket = sockets[uuid] else { return }
//        let command = Command(commandType: .swipeLeft, identificationType: .accessibilityId, identification: ElementIdentification(elementIdentification: "swipe_group"), waitTimeout: 0)
//        self.send(message: ServerToClientMessage(id: uuid, command: command, createdAt: Date()), to: .socket(socket))
//    }
//    
//    private func pickerSetValue() {
//        guard let socket = sockets[uuid] else { return }
//        let command = Command(commandType: .setPicketValue, identificationType: .accessibilityId, identification: ElementIdentification(elementIdentification: "test_picker"), waitTimeout: 0)
//        self.send(message: ServerToClientMessage(id: uuid, command: command, createdAt: Date()), to: .socket(socket))
//    }
//    
    private func scrollTableDownForStaticTextCell(text: String) {
        guard let socket = sockets[uuid] else { return }
        let command = Command(commandType: .tableStaticTextCellScrollDown, identificationType: .staticText, identification: ElementIdentification(staticText: text), waitTimeout: 0)
        self.send(message: ServerToClientMessage(id: uuid, command: command, createdAt: Date()), to: .socket(socket))
    }
    
    private func scrollTableUpForStaticTextCell(text: String) {
        guard let socket = sockets[uuid] else { return }
        let command = Command(commandType: .tableStaticTextCellScrollUp, identificationType: .staticText, identification: ElementIdentification(staticText: text), waitTimeout: 0)
        self.send(message: ServerToClientMessage(id: uuid, command: command, createdAt: Date()), to: .socket(socket))
    }
    
    private func testSetSliderValue() {
        guard let socket = sockets[uuid] else { return }
        let command = Command(commandType: .setSliderValue, identificationType: .accessibilityId, identification: ElementIdentification(elementIdentification: "test_slider"), waitTimeout: 0)
        self.send(message: ServerToClientMessage(id: uuid, command: command, createdAt: Date()), to: .socket(socket))
    }
    
    private func sendDisconnect() {
        guard let socket = sockets[uuid] else { return }
        // send shutdown message to the client
        self.send(message: ShutdownMessage(id: uuid, sentAt: Date()), to: .socket(socket))
    }
}
