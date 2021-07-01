//
//  Errors.swift
//  
//
//  Created by Zhanna Moskaliuk on 17.06.2021.
//

import Foundation

enum CommandExecutionError: String, Error {
    
    case unknownCommand
    case unknownElement
    case unknownIdentifier
    
    var errorDescriprion: String {
        switch self {
        case .unknownCommand:
            return "Could not find such command"
        case .unknownElement:
            return "Could not find such element"
        default:
            return "error"
            
        }
    }
}
