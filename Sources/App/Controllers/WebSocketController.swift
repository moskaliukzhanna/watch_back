//
//  WebSocketController.swift
//
//
//  Created by Zhanna Moskaliuk on 01.06.2021.
//

import Foundation
import Vapor
import Dispatch

enum WebSocketSendOption {
    //    case id(UUID), socket(WebSocket)
    //    case all, ids([UUID])
    case socket(WebSocket)
}

final class WebSocketController {
    let lock: Lock
    //    var socketsUUIDDict: [ConnectionSource: String] = [:]
    var sockets: [String: WebSocket] = [:]
    var socketsUUIDDict: [ConnectionSource: [String: WebSocket]] = [:]
    let logger: Logger
    private let decoder = JSONDecoder()
    private lazy var timer: DispatchSourceTimer = DispatchSource.makeTimerSource()
    private var connectionCount = 0
    private var commandsArray = [Codable]()
    // TODO: - remove those dummies later
    var commandsCount = 0
    var isSend = false
    
    init() {
        self.lock = Lock()
        self.logger = Logger(label: "WebSocketController")
    }
    
    func connect(_ ws: WebSocket) {
        let uuid = UUID().uuidString
        self.lock.withLockVoid {
            self.sockets[uuid] = ws
            logger.info("Connection #\(sockets.count)")
            logger.info("WS :\(uuid) \(ws)")
        }
        ws.onBinary { [weak self] ws, buffer in
            guard let self = self,
                  let data = buffer.getData(
                    at: buffer.readerIndex, length: buffer.readableBytes) else {
                        return
                    }
            
            self.onData([uuid: ws], data)
        }
        ws.onText { [weak self] ws, text in
            guard let self = self,
                  let data = text.data(using: .utf8) else {
                      return
                  }
            
            self.onData([uuid: ws], data)
        }
        
        // Send initial message to track handshake was established
        let initialMessage = OutcomingMessage(method: .outcomingMessage, path: .initial, data: nil)
        send(message: initialMessage, to: .socket(ws))
        sendTestMessages()
        // Send test messages after all connections have been established or after delay
//        let timer: DispatchSourceTimer = DispatchSource.makeTimerSource()
//        timer.setEventHandler { [weak self] in
//            guard let self = self else { return }
//            if !self.isSend {
//            self.sendTestMessages()
//            self.isSend = true
//            }
//            timer.cancel()
//        }
//        timer.schedule(deadline: .now() + 20, repeating: .seconds(0), leeway: .seconds(0))
//        if #available(OSX 10.14.3,  *) {
//            timer.activate()
//
//        }
    }
    
    // "userNotificationCenter.requestAuthorization.setState"
    
    private func sendTestMessages() {
        commandsArray.append(OutcomingMessage(method: .outcomingMessage, path: .launch, data: Details(timeout: 0)))
//        commandsArray.append(OutcomingMessage(method: .outcomingMessage, path: .touch, data: Details(using: .id, value: "table_button")))
//        commandsArray.append(OutcomingMessage(method: .outcomingMessage, path: .scrollTableDown, data: Details(using: .coordinates, coordinates: Coordinates(x1: 180, y1: 373))))
        
        // Request authorization
        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "userNotificationCenter.requestAuthorization.setState", passthrough: AnyCodable(value: true)))
        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "userNotificationCenter.requestAuthorization.call", options: [.alert, .badge, .sound, .provisional]))
        
        // Get notifications settings
//        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "userNotificationCenter.getNotificationSettings.setState", passthrough: AnyCodable(value: true)))
//        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "userNotificationCenter.getNotificationSettings.callback", callbackId: "1234"))
        
//        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path: "userNotificationCenter.getNotificationSettings.call", callbackId: "1234"))
        
        
//        commandsArray.forEach { command in
//            executeCommand(message: command)
//        }
        
//        let timer: DispatchSourceTimer = DispatchSource.makeTimerSource()
//        timer.setEventHandler { [weak self] in
//            guard let self = self else { return }
//            if !self.isSend {
//            self.sendTestMessages()
//            self.isSend = true
//            }
//            timer.cancel()
//        }
//        timer.schedule(deadline: .now() + 20, repeating: .seconds(0), leeway: .seconds(0))
//        if #available(OSX 10.14.3,  *) {
//            timer.activate()
//
//        }
        
        Task {
            for command in commandsArray {
                try await Task.sleep(nanoseconds: 10000000000)
                executeCommand(message: command)
            }
        }
    }
    
    
    
    func send<T: Codable>(message: T, for source: ConnectionSource) {
        guard let socketDict = socketsUUIDDict[source], let socket = socketDict.first?.value else {
            logger.info("Failed to fetch Web Socket:\(source)")
            return
        }
        send(message: message, to: .socket(socket))
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
    
    private func onData(_ embededDict: [String: WebSocket], _ data: Data) {
        self.logger.info("\(String(data: data, encoding: .utf8) ?? "Malformed data")")
        
        handleData(embededDict, data)
    }
    
    private func handleData(_ embededDict: [String: WebSocket], _ data: Data) {
        if let executionResponse = decoder.decode(type: ExecutionResponse.self, data: data) {
            handleResponse(executionResponse)
        }
        if let messageResponse = decoder.decode(type: SocketStatusResponse.self, data: data) {
            handleResponse(messageResponse, embededDict: embededDict)
        }
    }
    
    private func handleResponse(_ response: ExecutionResponse) {
        let status = response.status
        let info = response.detail
        
        print("Command executed with status \(status) : \(info)")
    }
    
    private func handleResponse(_ response: SocketStatusResponse, embededDict: [String: WebSocket]) {
        let status = response.message
        
        if socketsUUIDDict.keys.contains(status) {
            socketsUUIDDict.removeValue(forKey: status)
        }
        socketsUUIDDict[status] = embededDict
        print(socketsUUIDDict)
    }
}

extension WebSocketController {
    fileprivate func executeCommand(message: Codable) {
        commandsCount += 1
        let source: ConnectionSource = message is OutcomingMessage ? .joinedUI : .joinedSwizzler
        if message is OutcomingMessage {
            send(message: message as! OutcomingMessage, for: source)
        } else {
            send(message: message as! SwizzlingCommand, for: source)
        }
    }
    
    
    private func goToWristLocationButtonTapButton() {
        commandsCount += 1
        
        let data = Details(using: .id, value: "go_wristLocation")
        let outcommingMessage = OutcomingMessage(method: .outcomingMessage, path: .touch, data: data)
        
        send(message: outcommingMessage, for: .joinedUI)
    }
    
    private func changeWristLocation() {
        
        let message = SwizzlingCommand(method: .outcomingMessage, path: "interfaceDevice.wristLocation.setTestValue", value: AnyCodable(value: "right"))
        send(message: message, for: .joinedSwizzler)
    }
    
    private func tapCheckWristLocation() {
        commandsCount += 1
        
        let data = Details(using: .id, value: "check_wristLocation")
        let outcommingMessage = OutcomingMessage(method: .outcomingMessage, path: .touch, data: data)
        
        send(message: outcommingMessage, for: .joinedUI)
    }
    
    private func testFindElement() {
        commandsCount += 1
        
        let data = Details(using: .id, value: "goToColorButton")
        let outcommingMessage = OutcomingMessage(method: .outcomingMessage, path: .element, data: data)
        
        send(message: outcommingMessage, for: .joinedUI)
    }
    
    private func testTapButton() {
        commandsCount += 1
        
        let data = Details(using: .id, value: "table_button")
        let outcommingMessage = OutcomingMessage(method: .outcomingMessage, path: .touch, data: data)
        
        send(message: outcommingMessage, for: .joinedUI)
    }
    
    private func testScrollDownTable() {
        commandsCount += 1
        
        let data = Details(using: .text, value: "21.11.2019.")
        let outcommingMessage = OutcomingMessage(method: .outcomingMessage, path: .scrollTableDown, data: data)
        
        send(message: outcommingMessage, for: .joinedUI)
    }
    
    private func testScrollUpTable() {
        commandsCount += 1
        
        let data = Details(using: .text, value: "23.10.2020.")
        let outcommingMessage = OutcomingMessage(method: .outcomingMessage, path: .scrollTableUp, data: data)
        
        send(message: outcommingMessage, for: .joinedUI)
    }
}
