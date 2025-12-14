import Starscream
import CoreVideo

// Note: It's good practice to make the class final
final class WebSockets: WebSocketDelegate {
    
    // Use 'any WebSocketClient' for the property type for better compatibility
    var socket: WebSocket
    var isConnected = false
    
    // 1. Add a closure property to notify when connected
    var onConnect: (() -> Void)?
    
    init(ip: String) {
        // Correct the host string to use the WebSocket protocol
        let urlString = "ws://\(ip):9090" // Assuming port 9090 for rosbridge
        guard let url = URL(string: urlString) else {
            fatalError("Invalid URL: \(urlString)")
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        
        self.socket = WebSocket(request: request)
        self.socket.delegate = self
        
        self.openConnection() // Connect immediately in the initializer
    }
    
    // Renamed function for clarity
    func openConnection(){
        if isConnected {
            print("Socket Already Connected!")
            return
        }
        socket.connect()
        isConnected = true
    }
    
    // MARK: - WebSocketDelegate Protocol Implementation
    // This MUST match the Starscream protocol exacty
    public func didReceive(event: WebSocketEvent, client: any WebSocketClient) {
        
        
        switch event {
        case .connected(let headers):
            isConnected = true
            print("websocket is connected: \(headers)")
            self.onConnect?()
        case .disconnected(let reason, let code):
            isConnected = false
            print("websocket is disconnected: \(reason) with code: \(code)")
        case .text(let string):
            // This is where you would receive ROS service responses or feedback
            print("Received text: \(string.prefix(100))...")
        case .binary(let data):
            print("Received binary data: \(data.count) bytes")
        case .cancelled, .error:
            isConnected = false
            // You may want to implement a reconnection logic here
        case .peerClosed:
            break
        default:
            break
        }
    }
    
    func sendJSONString(jsonString: String) {
        if isConnected {
            // Starscream has a dedicated write(string:) method for text data
            socket.write(string: jsonString)
        } else {
            print("Cannot send data: Socket Not Connected!")
        }
    }
    
    func disconnect(){
        if isConnected {
            // You can use a specific CloseCode if needed, but simple disconnect works
            socket.disconnect()
        } else {
            print("Socket Not Connected!")
        }
    }
    
    // You will need the convertTimestampToROS here or in an extension
}
