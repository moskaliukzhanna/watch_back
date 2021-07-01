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
    case notEnabled
    case noIdentificationProvided
    
    var errorDescriprion: String {
        switch self {
        case .unknownCommand:
            return "Could not find such command"
        case .unknownElement:
            return "Could not find such element"
        case .unknownIdentifier:
            return "Couild not find mathing element"
        case .notEnabled:
            return "Element is not selected"
        case .noIdentificationProvided:
            return "There no any identification such as accessibilityId/staticText"
        default:
            return "error"
            
        }
    }
}
