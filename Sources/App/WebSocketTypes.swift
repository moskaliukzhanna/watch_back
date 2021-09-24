//
//  WebSocketTypes.swift
//  
//
//  Created by Zhanna Moskaliuk on 02.06.2021.
//

import Foundation

enum WatchCommand: String, Codable {
    case element = "/element"
    case touch = "/touch/click"
    case screenshot = "/screenshot"
}

enum WebSocketMessageType: String, Codable {
    case outcomingMessage = "/POST" // server ---> client
    case incomingMessage = "/GET" // client ---> server
}

struct OutcomingMessage: Codable {
    let method: WebSocketMessageType
    let path: WatchCommand
    let data: Details?
}

struct Details: Codable {
    let element: Element?
    let timeout: Int?
    let using: Identification?
    let value: String?
}

enum Identification: String, Codable {
    case id = "id"
    case text = "text"
}

struct Element: Codable {
    let id: String?
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
