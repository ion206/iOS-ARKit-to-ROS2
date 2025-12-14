//
//  ROSBridgeClient.swift
//  iOSDepthToROS2
//
//  Created by Ayan Syed on 12/13/25.
//


import ARKit
import CoreVideo
import Foundation


class ROSBridgeClient {
    
    let host: String = "192.XXX.XXX.XX"
    var websocket: WebSockets
    
    init(){
        websocket = WebSockets(ip: host)
        
        // 1. Set the onConnect closure to call advertise
        websocket.onConnect = { [weak self] in
            // Use a slight delay to ensure the WebSocket is fully ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?.advertiseTopics()
            }
        }
    }
    
    
    
    func publishDepth(data: Data, width: Int, height: Int) {
        
        // 1. Base64 Encode the Data (The critical step)
        let base64String = data.base64EncodedString() // Swift handles this easily!
        
        let currentTimestamp = Date().timeIntervalSince1970
        let rosTime = self.convertTimestampToROS(timestamp: currentTimestamp)

        // 2. Construct the JSON payload for rosbridge
        let payload: [String: Any] = [
            "op": "publish",
            "topic": "/arkit/depth_raw",
            "type": "sensor_msgs/msg/Image",
            "msg": [
                "header": ["stamp": rosTime, "frame_id": "camera_depth_frame"],
                "height": height,
                "width": width,
                "encoding": "32FC1",
                "is_bigendian": 0,
                "step": width * 4, // 4 bytes per Float32
                "data": base64String
            ]
        ]

        // 3. Serialize to JSON and Send over WebSocket
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
            let jsonString = String(data: jsonData, encoding: .utf8)!
            
            // Send the JSON string
            websocket.sendJSONString(jsonString: jsonString)
        } catch {
            print("JSON serialization error: \(error)")
        }
    }
    
    func convertTimestampToROS(timestamp: TimeInterval) -> [String: Int] {
            
            // Use the current time since UNIX epoch (1970-01-01 UTC)
            let totalSeconds = Date().timeIntervalSince1970
            
            // 1. Calculate the whole seconds component (int32 sec)
            let sec = Int32(floor(totalSeconds))
            
            // 2. Calculate the fractional nanoseconds component (uint32 nanosec)
            // Fractional part = totalSeconds - whole seconds
            let fractionalPart = totalSeconds - Double(sec)
            
            // Nanoseconds = fractional part * 1,000,000,000
            let nanosec = UInt32(fractionalPart * 1_000_000_000)
            
            // ROS uses a JSON structure of {"sec": <int>, "nanosec": <uint>}
            return [
                "sec": Int(sec),
                "nanosec": Int(nanosec) // JSON requires Int, but we pass the UInt32 value
            ]
        }
    
        private func advertiseTopics() {
            print("Advertising topics to rosbridge...")
            
            let depthTopic = "/arkit/depth_raw"
            let depthType = "sensor_msgs/msg/Image"
            
            // Construct the advertise message for the depth image
            let payload: [String: Any] = [
                "op": "advertise",
                "topic": depthTopic,
                "type": depthType
            ]
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
                let jsonString = String(data: jsonData, encoding: .utf8)!
                
                // Send the JSON string
                websocket.sendJSONString(jsonString: jsonString)
                print("Successfully advertised: \(depthTopic)")
                
                // You would advertise camera_info and pose here as well:
                // self.advertiseCameraInfo()
                // self.advertisePose()
                
            } catch {
                print("Advertise JSON serialization error: \(error)")
            }
        }
    
}
