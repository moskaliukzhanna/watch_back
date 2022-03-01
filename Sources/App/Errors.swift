//
//  Errors.swift
//  
//
//  Created by Zhanna Moskaliuk on 17.06.2021.
//

import Foundation

import Foundation

enum WatchError: Int, Codable {
    case success = 0
    case unknownCommand
    case unknownElement
    case unknownIdentifier
    case notEnabled
    case noIdentificationProvided
    case defaultImplementation
    
    var descriprion: String {
        switch self {
        case .success:
            return "The command executed successfully"
        case .unknownCommand:
            return "Could not find such command"
        case .unknownElement:
            return "Could not find such element"
        case .unknownIdentifier:
            return "Couild not find mathing element"
        case .notEnabled:
            return "Element is not selected"
        case .noIdentificationProvided:
            return "There no any identification such as id/text"
        case .defaultImplementation:
            return "Default implementation of the command was called"
        }
    }
}

struct ResponseMessage: Codable {
    let status: Int
    let summary: String
    let detail: String
    let message: String
    
    
}

struct ExecutionResponse: Codable {
    
    let status: Int
    let summary: String
    let detail: String
    
    
//    init(status: WatchError) {
//        self.summary = "\(status)"
//        self.status = status.rawValue
//        self.detail = status.descriprion
//    }
}

struct SocketStatusResponse: Codable {
    let message: ConnectionSource
}
