//
//  Errors.swift
//  
//
//  Created by Zhanna Moskaliuk on 17.06.2021.
//

import Foundation

enum CommandExecutionError: Error {
    case success
    case failure
}

extension CommandExecutionError {
    var errorDescription: String {
        switch self {
        case .success:
            return "Command was successfully executed"
        case .failure:
            return "Command execution has failed"
        }
    }
}
