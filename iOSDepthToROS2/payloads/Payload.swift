//
//  Payload.swift
//  iOSDepthToROS2
//
//  Created by Ayan Syed on 12/14/25.
//


//ABSTRACT CLASS

import Foundation

class Payload{
    
    var op: String = "publish"
    var topic: String = "/arkit/"
    var type: String = "sensor_msgs/msg/"
    var msg: [String: Any] = [:]
    
    var data: Data = Data()
    
    init(topicField: String, msgType: String){
        self.topic = topic + topicField // TOPIC NAME Ex. /arkit/Image/testImage
        self.type = type + msgType // TOPIC TYPE Ex. /sensor_msgs/msg/Image
    }
    
    
    func updateData(info: Data){
        self.data = info
    }
    func getPayload(frameTime: TimeInterval) -> String {
        self.constructPayload(frameTime: frameTime) //Update msg
        //print("CONSTRUCTED PAYLOAD")
        let jsonString = self.serializeToJSON()
        //print("SERIALIZED PAYLOAD")
        return jsonString
    }
    
    open func constructPayload(frameTime: TimeInterval) {
        print("UNIMPLEMENTED: contructPayload()")
    }
    
    open func getCurrentTimestamp() -> [String: Int]{
        let currentTimestamp = Date().timeIntervalSince1970
        let rosTime = self.convertTimestampToROS(timestamp: currentTimestamp)
        return rosTime
    }
	
	func getBSONPayload(frameTime: TimeInterval) -> Data{return Data()}
    
    

    // Turns a msg into JSON Format
    open func serializeToJSON() ->  String{
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self.msg, options: [])
            let jsonString = String(data: jsonData, encoding: .utf8)!
            return jsonString
        } catch {
            print("JSON serialization error: \(error)")
            return ""
        }
        
    }
    
    
    open func convertBase64() -> String {
        let base64String = self.data.base64EncodedString() // Swift handles this easily!
        return base64String
    }
    
    open func convertTimestampToROS(timestamp: TimeInterval) -> [String: Int] {
        // Use the frame's timestamp since UNIX epoch (1970-01-01 UTC)
        let totalSeconds = timestamp // Use the provided ARFrame time
        
        // 1. Calculate the whole seconds component (int32 sec)
        let sec = Int32(floor(totalSeconds))
        
        // 2. Calculate the fractional nanoseconds component (uint32 nanosec)
        let fractionalPart = totalSeconds - Double(sec)
        let nanosec = UInt32(fractionalPart * 1_000_000_000)
        
        // ROS uses a JSON structure of {"sec": <int>, "nanosec": <uint>}
        return [
            "sec": Int(sec),
            "nanosec": Int(nanosec)
        ]
    }
    
}
