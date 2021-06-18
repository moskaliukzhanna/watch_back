//
//  TestController.swift
//  
//
//  Created by Zhanna Moskaliuk on 01.06.2021.
//

import Foundation
import Vapor

struct TestController: RouteCollection {
    let wsController: WebSocketController
    
    func boot(routes: RoutesBuilder) throws {
        // provide
        routes.webSocket("socket", onUpgrade: self.webSocket)
        
    }
   
    func webSocket(req: Request, socket: WebSocket) {
        self.wsController.connect(socket)
    }
    
//    func onTestMessageReceinved(_ ws: WebSocket, _ id: UUID, _ message: ClientToServerMessage) {
//
//
//    }
    
}
