//
//  WebSocketTypes.swift
//  
//
//  Created by Zhanna Moskaliuk on 02.06.2021.
//

import Foundation

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
