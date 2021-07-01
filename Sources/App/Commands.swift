//
//  .swift
//  
//
//  Created by Zhanna Moskaliuk on 17.06.2021.
//

import Foundation

enum CommandType: String, Codable {
    case isEnabled
    case isSelected
    case tap
    case makesreenshot
    case checkGoToScreen
    case wait
    case tapAndWait
    case staticTextExists
    case disconnect
}

enum ElementIdentificationType: String, Codable {
    case accessibilityId
    case staticText
}

struct ElementIdentification: Codable {
    let elementIdentification: String?
    let staticText: String?
}

struct Command: Codable {
    let commandType: CommandType
    let identificationType: ElementIdentificationType
    let identification: String
    var element: ElementType? = nil
    var waitTimeout: Int = 0
}

enum ElementType: UInt, Codable {
    case button = 0
}

struct AccessibilityId: String, Codable {
//    let
}
