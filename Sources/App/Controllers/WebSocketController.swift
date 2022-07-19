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
    case socket(WebSocket)
}

final class WebSocketController {
    let lock: Lock
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
    }
    
    private func sendTestMessages() {
        commandsArray.append(OutcomingMessage(method: .outcomingMessage, path: .launch, data: Details(timeout: 0)))
        //        commandsArray.append(OutcomingMessage(method: .outcomingMessage, path: .pressHomeButton, data: Details(timeout: 2)))
        // Request authorization
        //        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "/userNotificationCenter.requestAuthorization.setState", passthrough: AnyCodable(value: true)))
        //        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "/userNotificationCenter.requestAuthorization.call", options: [.alert, .badge, .sound]))
        commandsArray.append(OutcomingMessage(method: .outcomingMessage, path: .touch, data: Details(using: .id, value: "go_wristLocation")))
        
        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path: "/coreMotion.isDeviceMotionAvailable.setTestValue", value: AnyCodable(value: true)))
        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path: "/coreMotion.isAccelerometerAvailable.setTestValue", value: AnyCodable(value: true)))
        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path: "/coreMotion.isAccelerometerAvailable.getTestFrameworkValue", value: AnyCodable(value: true)))
        
        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path: "/coreMotion.isDeviceMotionActive.setTestValue", value: AnyCodable(value: true)))
        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path: "/coreMotion.isAccelerometerActive.setTestValue", value: AnyCodable(value: true)))
        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path: "/coreMotion.deviceMotionUpdateInterval.setTestValue", value: AnyCodable(value: 2.0)))
        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path: "/coreMotion.isDeviceMotionAvailable.getFrameworkValue"))
        //
        ////        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path: "/coreMotion.startDeviceMotionUpdatesWithHandler.setState", passthrough: AnyCodable(value: true)))
        ////        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "/coreMotion.startDeviceMotionUpdatesWithHandler.call"))
        //
        
        //
        //        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "/coreMotion.stopDeviceMotionUpdates.setState", passthrough: AnyCodable(value: true)))
        //        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "/coreMotion.stopDeviceMotionUpdates.call"))
        //
        //        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path: "/coreMotion.deviceMotion.setTestValue", value: AnyCodable(value:
        //                                                                                                                                            [
        //                                                                                                                                                "rotationRate": [
        //                                                                                                                                                    "x": 1.5,
        //                                                                                                                                                    "y": 0.5,
        //                                                                                                                                                    "z": 2.5],
        //                                                                                                                                                "gravity": [
        //                                                                                                                                                    "x": 0.5,
        //                                                                                                                                                    "y": 0.5,
        //                                                                                                                                                    "z": 0.5],
        //                                                                                                                                                "userAcceleration":[
        //                                                                                                                                                    "x": 0.5,
        //                                                                                                                                                    "y": 0.5,
        //                                                                                                                                                    "z": 0.5],
        //                                                                                                                                                "timestamp": 1581351985
        //                                                                                                                                            ]
        //
        //                                                                                                                                         )))
        //        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path: "/coreMotion.startDeviceMotionUpdatesWithHandler.setState", passthrough: AnyCodable(value: true)))
        //        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "/coreMotion.startDeviceMotionUpdatesWithHandler.call"))
        //
        //        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path: "/coreMotion.deviceMotion.getFrameworkValue"))
        //        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path: "/coreMotion.deviceMotion.getTestFrameworkValue"))
        
        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path: "/coreMotion.accelerometerUpdateInterval.setTestValue", value: AnyCodable(value: 2.0)))
        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "/coreMotion.accelerometerUpdateInterval.getTestFrameworkValue"))
        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "/coreMotion.accelerometerUpdateInterval.getFrameworkValue"))
        
        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "/coreMotion.startAccelerometerUpdates.setState", passthrough: AnyCodable(value: true)))
        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "/coreMotion.startAccelerometerUpdates.call"))
        
        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "/coreMotion.accelerometerData.setTestValue", value: AnyCodable(value:
                                                                                                                                                    [
                                                                                                                                                        "acceleration": [
                                                                                                                                                            "x": 2.5,
                                                                                                                                                            "y": 0.5,
                                                                                                                                                            "z": 3.5
                                                                                                                                                        ],
                                                                                                                                                        "timestamp": 1581351985])))
        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "/coreMotion.accelerometerData.getTestFrameworkValue"))
        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "/coreMotion.accelerometerData.getFrameworkValue"))
        
        //
        //
        //        commandsArray.append(OutcomingMessage(method: .outcomingMessage, path: .alertTap, data: Details(using: .text, value: "Allow")))
        //
        //        // Supports content extensions
        //        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "/userNotificationCenter.supportsContentExtensions.setTestValue", value: AnyCodable(value: true)))
        //        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "/userNotificationCenter.supportsContentExtensions.getTestFrameworkValue", timeout: 3.0))
        //
        //        // Set Meal category
        //        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "/userNotificationCenter.setNotificationCategories.setState", passthrough: AnyCodable(value: true)))
        //        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "/userNotificationCenter.setNotificationCategories.call", categories:
        //                                                [NotificationCategory(identifier: "MealCategory",
        //                                                                      actions: [NotificationAction(identifier: "MealTime", title: "Have a meal"),
        //                                                                                NotificationAction(identifier: "PostponeTime", title: "Ask me in an hour"),
        //                                                                                NotificationAction(identifier: "TomorrowTime", title: "Ask me in an tomorrow")])]))
        //
        //        // Add notitfication request - Meal
        //        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "/userNotificationCenter.addNotificationRequest.setState", passthrough: AnyCodable(value: true)))
        //        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "/userNotificationCenter.addNotificationRequest.call", notificationRequest: NotificationRequest(identifier: "MealTime", title: "It's time to eat something", body: "You scheduled your dinner for this hour", categoryIdentifier: "MealCategory", triggerTimeInterval: 0.5)))
        //
        //        commandsArray.append(OutcomingMessage(method: .outcomingMessage, path: .alertTap, timeout: 7.0, data: Details(using: .text, value: "Have a meal")))
        //
        // Set Tea category
        //          commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "userNotificationCenter.setNotificationCategories.setState", passthrough: AnyCodable(value: true)))
        //          commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "userNotificationCenter.setNotificationCategories.call", categories:
        //                                                  [NotificationCategory(identifier: "TeaCategory",
        //                                                                        actions: [NotificationAction(identifier: "TakeTea", title: "Take a tea break"),
        //                                                                                  NotificationAction(identifier: "TakeCoffe", title: "More coffe??? That's not healthy")])]))
        //
        //           // Add notitfication request - Tea
        //          commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "userNotificationCenter.addNotificationRequest.setState", passthrough: AnyCodable(value: true)))
        //          commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "userNotificationCenter.addNotificationRequest.call", notificationRequest: NotificationRequest(identifier: "TeaTime", title: "Tea Break", body: "It is time for tea", categoryIdentifier: "TeaCategory", triggerTimeInterval: 1.0)))
        //
        //        commandsArray.append(OutcomingMessage(method: .outcomingMessage, path: .alertTap, timeout: 7.0, data: Details(using: .text, value: "TakeCoffe")))
        
        
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
                    
                case .socket(let socket):
                    return [socket]
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
        if let messageResponse = decoder.decode(type: ConnectionSource.self, data: data) {
            
            handleResponse(messageResponse, embededDict: embededDict)
        }
    }
    
    private func handleResponse(_ response: ExecutionResponse) {
        let status = response.status
        let info = response.detail
        
        print("Command executed with status \(status) : \(info)")
    }
    
    private func handleResponse(_ response: ConnectionSource, embededDict: [String: WebSocket]) {
        let status = response
        
        if socketsUUIDDict.keys.contains(status) {
            socketsUUIDDict.removeValue(forKey: status)
        }
        
        socketsUUIDDict[status] = embededDict
        print(socketsUUIDDict)
        
        if socketsUUIDDict.keys.contains(.ui_connect) &&
            socketsUUIDDict.keys.contains(.swizzling_connect) {
            sendTestMessages()
        }
    }
}

extension WebSocketController {
    fileprivate func executeCommand(message: Codable) {
        commandsCount += 1
        let source: ConnectionSource = message is OutcomingMessage ? .ui_connect : .swizzling_connect
        if message is OutcomingMessage {
            send(message: message as! OutcomingMessage, for: source)
        } else {
            send(message: message as! SwizzlingCommand, for: source)
        }
    }
}
