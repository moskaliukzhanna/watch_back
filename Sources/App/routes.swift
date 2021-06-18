import Fluent
import Vapor

func routes(_ app: Application) throws {
  let webSocketController = WebSocketController()
  try app.register(collection: TestController(wsController: webSocketController))
}
//
//func routes(_ app: Application) throws {
//    app.get { req in
//        return "It works!"
//    }
//
//    app.get("hello") { req -> String in
//        return "Hello, world!"
//    }
