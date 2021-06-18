//
//  WebSocketTypes.swift
//  
//
//  Created by Zhanna Moskaliuk on 02.06.2021.
//

import Foundation

enum TestMessageType: String, Codable {
    case clientToServer
    case serverToClient, handshake
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
    let success: Bool
    let message: String
    let id: UUID?
    var answered: Bool
    let content: String
    let createdAt: Date?
}

