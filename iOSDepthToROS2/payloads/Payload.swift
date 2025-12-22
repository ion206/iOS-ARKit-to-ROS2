//
//  Payload.swift
//  iOSDepthToROS2
//
//  Created by Ayan Syed on 12/14/25.
//


//This OOP payload system uses a modular Inheritance model to standardize how different types of sensor data are formatted for ROS
//A base Payload class defines common attributes like timestamps and topic names, while specialized child classes (e.g., ImagePayload, OdometryPayload) implement their own logic to serialize raw ARKit data into either JSON or BSON formats
//By encapsulating the complex ROS message structures within these objects, the rest of the app can stream diverse data types through a single, clean interface without needing to manage low-level protocol details
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
	
	//To be overrided in Child Classes
	func getBSONPayload(frameTime: TimeInterval) -> Data{return Data()}
    
    

    // Turns a msg into JSON Format
	//Base function here just returns the serialized self.msg Data of the object
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
