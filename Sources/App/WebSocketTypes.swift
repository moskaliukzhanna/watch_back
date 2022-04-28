//
//  WebSocketTypes.swift
//  
//
//  Created by Zhanna Moskaliuk on 02.06.2021.
//

import Foundation
import Vapor

enum WatchCommand: String, Codable {
    case initial = "/init"
    case shutdown = "/shutdown"
    case element = "/element"
    case touch = "/touch/click"
    case text = "/text"
    case textColor = "/text/color"
    case complicationTap = "complication/tap"
    case screenshot = "/screenshot"
    case scrollTableDown = "/table/scroll/down"
    case scrollTableUp = "/table/scroll/up"
    case pressHomeButton = "press/homebutton"
    case launch = "/launch"
    case longPress = "/longPress"
}

enum WebSocketMessageType: String, Codable {
    case outcomingMessage = "POST" // server ---> client
    case incomingMessage = "GET" // client ---> server
}

struct OutcomingMessage: Codable {
    let method: WebSocketMessageType
    let path: WatchCommand
    var data: Details? = nil
}

struct Details: Codable {
    var element: Element? = nil
    var timeout: Int? = nil
    var using: Identification? = nil
    var coordinates: Coordinates? = nil
    var value: String? = nil
    var pressDuration: Double? = nil
}

enum Identification: String, Codable {
    case id = "id"
    case text = "text"
    case coordinates = "coordinates"
}

struct Coordinates: Codable {
    let x1: Int?
    let y1: Int?
    var x2: Int? = nil
    var y2: Int? = nil
}

struct Element: Codable {
    let id: String?
}

struct SwizzlingCommand: Codable {
    var method: WebSocketMessageType
    var path: String
    var value: AnyCodable? = nil
    
    
    var callbackId: String? = nil
    var passthrough: AnyCodable? = nil
    var granted: AnyCodable? = nil
    var options: Set<NotificationOptions>? = nil
    var notificationSettings: NotificationStatus? = nil
    var requestId: String? = nil
    var categories: [NotificationCategory]? = nil
    var notificationRequest: NotificationRequest? = nil
    var notification: Notification? = nil
    var response: NotificationResponse? = nil
    var identifiers: [String]? = nil
}

struct NotificationStatus: Codable {
    var authorizationStatus: AuthorizationStatus? = nil
}

enum NotificationOptions: String, Codable {
    case alert, sound, badge, provisional
}

enum AuthorizationStatus: String, Codable {
    case notDetermined, denied, authorized, provisional
}

struct NotificationCategory: Hashable, Codable {
    let identifier: String
    let actions: Set<NotificationAction>
}

struct NotificationAction: Hashable, Codable {
    let identifier: String
    let title: String
}

struct NotificationRequest: Codable {
    let identifier: String
    let title: String
    let body: String
    let categoryIdentifier: String
    let triggerTimeInterval: TimeInterval?
}

struct Notification: Codable {
    let identifier: String
    let title: String
    let body: String
    let categoryIdentifier: String
    let deliveryDate: Int?
}

struct NotificationResponse: Codable {
    let actionIdentifier: String
    let notificationIdentifier: String
}

enum TestMessageType: String, Codable {
    case clientToServer, response
    case serverToClient, handshake, disconnect
}

struct TestMessageSinData: Codable {
    let type: TestMessageType
    let id: UUID
}

struct TestMessageHandshake: Codable {
    let type = TestMessageType.handshake
    let id: UUID
}

struct ClientToServerMessage: Codable {
    let content: String
}

struct ServerToClientMessage: Codable {
    let type = TestMessageType.serverToClient
    let id: UUID?
    let command: Command
    let createdAt: Date?
}

struct ClientToServerResponse: Codable {
    let type: TestMessageType
    let id: UUID?
    let response: CommandExecutionResult
}

struct ShutdownMessage: Codable {
    let type = TestMessageType.disconnect
    let id: UUID?
    let sentAt: Date?
}

struct CommandExecutionResult: Codable {
    var success: Bool
    let command: Command
    let error: String?
}
