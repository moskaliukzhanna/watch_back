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
    case elementSreenshot
    case setSliderValue
//    case wait
    case tapAndWait
    case tapBackButton
    case staticTextExists
    case switchValue
//    case swipeLeft
//    case setPicketValue
    case swipeRight
    case swipeDown
    case tableStaticTextCellScrollDown
    case tableStaticTextCellScrollUp
    case disconnect
}

enum ElementIdentificationType: String, Codable {
    case accessibilityId
    case staticText
}

struct ElementIdentification: Codable {
    var elementIdentification: String? = nil
    var staticText: String? = nil
}

struct Command: Codable {
    let commandType: CommandType
    var identificationType: ElementIdentificationType = .accessibilityId
    var identification: ElementIdentification? = nil
//    let accessibilityId: String?
//    let staticText: String?
    var element: ElementType? = nil
    var waitTimeout: Int = 0
}

enum ElementType: UInt, Codable {
    case button = 0
}
