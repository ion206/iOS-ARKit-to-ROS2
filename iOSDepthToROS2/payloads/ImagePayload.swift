//
//  ImagePayload.swift
//  iOSDepthToROS2
//
//  Created by Ayan Syed on 12/14/25.
//

import Foundation
import SwiftBSON

class ImagePayload: Payload{
    let isBigEndian: Int = 0
    let topicType: String = "Image/"
    let msgType: String = "Image"
    
    var encoding: String = "32FC1"
    var height: Int = 0
    var width: Int = 0
    var stepMultiplier = 4 // 4 bytes per Float32
	
	var payload: BSONDocument = [:]
    
    
    init(topicName: String){
        super.init(topicField: (self.topicType + topicName), msgType: self.msgType)
        print("Created Image Topic Class: " + self.topic + " with Type: " + self.type)
    }
    
    init(topicName: String, encoding: String){
        super.init(topicField: (self.topicType + topicName), msgType: self.msgType)
        self.encoding = encoding
        print("Created Image Topic Class: " + self.topic + " with Type: " + self.type)
    }
    
    
    func updateData(data: Data, height: Int, width: Int) {
        super.updateData(info: data)
        self.height = height
        self.width = width
    }
    
	
	override func getBSONPayload(frameTime: TimeInterval) -> Data {
	    self.constructBSONPayload(frameTime: frameTime) //Update msg
		return self.payload.toData()
	}
	
    override func constructPayload(frameTime: TimeInterval){
	    //If we want to use JSON we can use this function
        let rosTime = self.convertTimestampToROS(timestamp: frameTime)
	    let payload: [String: Any] = [
            "op": self.op,
            "topic": self.topic,
            "type": self.topicType,
            "msg": [
                "header": ["stamp": rosTime, "frame_id": "camera_depth_frame"],
                "height": self.height,
                "width": self.width,
                "encoding": self.encoding,
                "is_bigendian": self.isBigEndian,
                "step": self.width * self.stepMultiplier,
                "data": self.convertBase64() //Converts class Payload Data to Base 64
            ],
		  "queue_length": 1
        ]
        self.msg = payload
    }
	
	
	func constructBSONPayload(frameTime: TimeInterval) {
	    let rosTime = self.convertTimestampToROS(timestamp: frameTime)
	    
	    // 1. Initialize an empty BSONDocument
	    var msg = BSONDocument()
	    
	    // 2. Build the Stamp
	    let stamp: BSONDocument = [
		   "sec": .int32(Int32(rosTime["sec"]!)),
		   "nanosec": .int32(Int32(rosTime["nanosec"]!))
	    ]
	    
	    // 3. Build the Header
	    let header: BSONDocument = [
		   "stamp": .document(stamp),
		   "frame_id": .string("camera_depth_frame")
	    ]
	    
	    // 4. Fill the Image Data
	    msg["header"] = .document(header)
	    msg["height"] = .int32(Int32(self.height))
	    msg["width"] = .int32(Int32(self.width))
	    msg["encoding"] = .string("rgb8")
	    msg["is_bigendian"] = .bool(false)
	    msg["step"] = .int32(Int32(self.width * 3))
	    
	    // Binary data handling for MongoDB SwiftBSON
		msg["data"] = .binary(try! BSONBinary(data: self.data, subtype: .generic))
	    
	    // 5. Final Top-Level Payload
	    let finalDoc: BSONDocument = [
		"op": .string(self.op),
		   "topic": .string(self.topic),
		   "type": .string(self.topicType),
		   "msg": .document(msg)
	    ]
	    
	    // To send this via Starscream:
	    // self.payloadData = try? finalDoc.toData()
	    self.payload = finalDoc
	}
    
}


