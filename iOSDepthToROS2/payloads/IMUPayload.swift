//
//  ImagePayload.swift
//  iOSDepthToROS2
//
//  Created by Ayan Syed on 12/14/25.
//

import Foundation
import simd



//Currently Unimplemented, I think this capbility is for visionOS only
//We dont NEED it for anything, might implement later

///Handles topic type: sensor_msg/msg/IIMU
class IMUPayload: Payload{
    let topicType: String = "IMU/"
    let msgType: String = "Imu"
    
    var angular_velocity_x: Double = 0.0
    var angular_velocity_y: Double = 0.0
    var angular_velocity_z: Double = 0.0
    
    var linear_acceleration_x: Double = 0.0
    var linear_acceleration_y: Double = 0.0
    var linear_acceleration_z: Double = 0.0
    
    
    init(topicName: String){
        super.init(topicField: (self.topicType + topicName), msgType: self.msgType)
        print("Created IMU Topic Class: " + self.topic + " with Type: " + self.type)
    }
    
    
    
    func updateIMU(newRot: simd_double3, newAcc: simd_double3) {
            // 1. Extract Angular Velocity (Gyroscope)
            var angular_velocity_x = Double(newRot.x)
            var angular_velocity_y = Double(newRot.y)
            var angular_velocity_z = Double(newRot.z)
            
            // 2. Extract Linear Acceleration
            // NOTE: ARKit's userAcceleration is NOT gravity-compensated,
            // but the gravity component is available separately in motion.gravity
            var linear_acceleration_x = Double(newAcc.x)
            var linear_acceleration_y = Double(newAcc.y)
            var linear_acceleration_z = Double(newAcc.z)
    }
    
    override func constructPayload(frameTime: TimeInterval){
        let rosTime = self.convertTimestampToROS(timestamp: frameTime)
        let payload: [String: Any] = [
            "op": self.op,
            "topic": self.topic,
            "type": self.topicType,
            "msg": [
                "header": ["stamp": rosTime, "frame_id": "camera_imu_frame"],
                // Orientation (Quaternion) - Leaving as identity for simplicity,
                // as orientation is often sourced from the TF tree (base_link)
                "orientation": [
                    "x": 0.0, "y": 0.0, "z": 0.0, "w": 1.0
                ],
                // Angular Velocity (rad/s)
                "angular_velocity": [
                    "x": angular_velocity_x,
                    "y": angular_velocity_y,
                    "z": angular_velocity_z
                ],
                // Linear Acceleration (m/s^2)
                "linear_acceleration": [
                    "x": linear_acceleration_x,
                    "y": linear_acceleration_y,
                    "z": linear_acceleration_z
                ],
                ],
		  "queue_length": 1
            ]
        self.msg = payload
    }
    
}


