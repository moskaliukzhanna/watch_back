import App
import Vapor

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
let app = Application(env)
//app.http.server.configuration.hostname = "192.168.1.3"
//app.http.server.configuration.port = 8080
defer { app.shutdown() }
try configure(app)
try app.run()
