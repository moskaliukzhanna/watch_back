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
        //        commandsArray.append(OutcomingMessage(method: .outcomingMessage, path: .touch, data: Details(using: .id, value: "table_button")))
        //        commandsArray.append(OutcomingMessage(method: .outcomingMessage, path: .scrollTableDown, data: Details(using: .coordinates, coordinates: Coordinates(x1: 180, y1: 373))))
        
        // Request authorization
        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "userNotificationCenter.requestAuthorization.setState", passthrough: AnyCodable(value: true)))
        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "userNotificationCenter.requestAuthorization.call", options: [.alert, .badge, .sound]))
        //        commandsArray.append(OutcomingMessage(method: .outcomingMessage, path: .alertTap, data: Details(using: .text, value: "Allow")))
        
        // Get notifications settings
        //        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "userNotificationCenter.getNotificationSettings.setState", passthrough: AnyCodable(value: true)))
        //        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "userNotificationCenter.getNotificationSettings.callback", callbackId: "1234"))
        
        //        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path: "userNotificationCenter.getNotificationSettings.call", callbackId: "1234"))
        //
        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "userNotificationCenter.supportsContentExtensions.setTestValue", value: AnyCodable(value: true)))
        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "userNotificationCenter.supportsContentExtensions.getTestFrameworkValue"))
        // Set Coffe category
        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "userNotificationCenter.setNotificationCategories.setState", passthrough: AnyCodable(value: true)))
        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "userNotificationCenter.setNotificationCategories.call", categories:
                                                [NotificationCategory(identifier: "CoffeCategory",
                                                                      actions: [NotificationAction(identifier: "Grabcoffe", title: "Do you want another coffe :)")])]))
        
        
        
        // Check categories which was set on the Watch
        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "userNotificationCenter.getNotificationCategories.setState", passthrough: AnyCodable(value: true)))
        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "userNotificationCenter.getNotificationCategories.call"))
        
        // Add notitfication request - Coffe
        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "userNotificationCenter.addNotificationRequest.setState", passthrough: AnyCodable(value: true)))
        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "userNotificationCenter.addNotificationRequest.call", notificationRequest: NotificationRequest(identifier: "CoffeTime", title: "Hey, it's coffe time", body: "Quick, grab your coffe", categoryIdentifier: "CoffeCategory", triggerTimeInterval: 10.0)))
        
        // Set Tea category
        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "userNotificationCenter.setNotificationCategories.setState", passthrough: AnyCodable(value: true)))
        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "userNotificationCenter.setNotificationCategories.call", categories:
                                                [NotificationCategory(identifier: "TeaCategory",
                                                                      actions: [NotificationAction(identifier: "TakeTea", title: "Take a tea break"),
                                                                                NotificationAction(identifier: "TakeCoffe", title: "More coffe??? That's not healthy")])]))
        
        // Add notitfication request - Tea
        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "userNotificationCenter.addNotificationRequest.setState", passthrough: AnyCodable(value: true)))
        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "userNotificationCenter.addNotificationRequest.call", notificationRequest: NotificationRequest(identifier: "TeaTime", title: "Tea Break", body: "It is time for tea", categoryIdentifier: "TeaCategory", triggerTimeInterval: 20.0)))
        
        // Make sreenshot
        commandsArray.append(OutcomingMessage(method: .outcomingMessage, path: .screenshot))
        
        
        // Set drinking Category
        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "userNotificationCenter.setNotificationCategories.setState", passthrough: AnyCodable(value: true)))
        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path: "userNotificationCenter.setNotificationCategories.call", categories:
                                                [NotificationCategory(identifier: "DrinkingCategory",
                                                                      actions: [NotificationAction(identifier: "TakeWater", title: "Are you drinking water?"),
                                                                                NotificationAction(identifier: "TakeJuice", title: "Are you drining juice?"),
                                                                                NotificationAction(identifier: "No", title: "No? Skip")])]))
        
        // Add notitfication request - Water
        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "userNotificationCenter.addNotificationRequest.setState", passthrough: AnyCodable(value: true)))
        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "userNotificationCenter.addNotificationRequest.call", notificationRequest: NotificationRequest(identifier: "DrinkTime", title: "It is time to hydralyte", body: "", categoryIdentifier: "DrinkingCategory", triggerTimeInterval: 10.0)))
        
        //        commandsArray.append(OutcomingMessage(method: .outcomingMessage, path: .alertTap, data: Details(using: .text, value: "Do you want another coffe :)")))
        
        
        //        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "userNotificationCenter.getPendingNotificationRequests.setState", passthrough: AnyCodable(value: true)))
        //        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:   "userNotificationCenter.getPendingNotificationRequests.call"))
        
        //        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "userNotificationCenter.removePendingNotificationRequests.setState", passthrough: AnyCodable(value: true)))
        //        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:   "userNotificationCenter.removePendingNotificationRequests.call", identifiers: ["CoffeTime"]))
        
        //        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "userNotificationCenter.removeAllPendingNotificationRequests.setState", passthrough: AnyCodable(value: true)))
        //        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:   "userNotificationCenter.removeAllPendingNotificationRequests.call"))
        
        //        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "userNotificationCenter.getPendingNotificationRequests.setState", passthrough: AnyCodable(value: true)))
        //        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:   "userNotificationCenter.getPendingNotificationRequests.call"))
        
        //        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "userNotificationCenter.getDeliveredNotifications.setState", passthrough: AnyCodable(value: true)))
        //        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "userNotificationCenter.getDeliveredNotifications.call"))
        
        //        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "userNotificationCenter.removeDeliveredNotifications.setState", passthrough: AnyCodable(value: true)))
        //        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "userNotificationCenter.removeAllDeliveredNotifications.call"))
        
        
        //        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "userNotificationCenter.getDeliveredNotifications.setState", passthrough: AnyCodable(value: true)))
        //        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "userNotificationCenter.getDeliveredNotifications.call"))
        
        //        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "userNotificationCenter.delegate.willPresentNotification.setState", passthrough: AnyCodable(value: true)))
        //        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "userNotificationCenter.delegate.willPresentNotification.call", notification: Notification(identifier: "CoffeTime", title: "Hey, it's coffe time", body: "Quick, grab your coffe", categoryIdentifier: "Grab coffe", deliveryDate: 10000)))
        //
        //        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "userNotificationCenter.delegate.didReceiveResponse.setState", passthrough: AnyCodable(value: true)))
        //        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "userNotificationCenter.delegate.didReceiveResponse.call", response: NotificationResponse(actionIdentifier: "Grab coffe", notificationIdentifier: "CoffeTime")))
        ////
        //        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:   "userNotificationCenter.delegate.openSettingsForNotifications.setState", passthrough: AnyCodable(value: true)))
        //        commandsArray.append(SwizzlingCommand(method: .outcomingMessage, path:  "userNotificationCenter.delegate.openSettingsForNotification.call", notification: Notification(identifier: "CoffeTime", title: "Hey, it's coffe time", body: "Quick, grab your coffe", categoryIdentifier: "Grab coffe", deliveryDate: 10000)))
        
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
        
        if socketsUUIDDict.keys.contains(.joinedUI) &&
            socketsUUIDDict.keys.contains(.joinedSwizzler) {
            sendTestMessages()
        }
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
}
