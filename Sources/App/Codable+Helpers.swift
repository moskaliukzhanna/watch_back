//
//  File.swift
//  
//
//  Created by Zhanna Moskaliuk on 28.02.2022.
//

import Foundation

extension JSONDecoder {
    func decode<T>(type: T.Type, data: Data) -> T? where T : Decodable {
        do {
            let result = try self.decode(type, from: data)
            return result
        } catch {
            print("Error decoding: \(type)")
            return nil
        }
    }
}
