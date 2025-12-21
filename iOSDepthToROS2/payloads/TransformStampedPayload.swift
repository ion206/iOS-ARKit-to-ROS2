//
//  ImagePayload.swift
//  iOSDepthToROS2
//
//  Created by Ayan Syed on 12/14/25.
//

import Foundation
import simd
import ARKit

class TransformStampedPayload: Payload{
	let isBigEndian: Int = 0
	let topicType: String = "Pose/"
	let msgType: String = "TransformStamped"
	let rotationMatrix = simd_float4x4(
	    simd_float4( 0, 0, 1, 0), // ROS X = -AR Z
	    simd_float4(1, 0,  0, 0), // ROS Y = -AR X
	    simd_float4( 0, 1,  0, 0), // ROS Z = +AR Y
	    simd_float4( 0, 0,  0, 1)
	)
    
    var x: Double = 0.0
    var y: Double = 0.0
    var z: Double = 0.0
    var quaternion: simd_quatf = simd_quatf()

    
    init(topicName: String){
        super.init(topicField: (self.topicType + topicName), msgType: self.msgType)
        self.type = "geometry_msgs/msg/TransformStamped"
        print("Created Image Topic Class: " + self.topic + " with Type: " + self.type)
    }
    
    
    
    func updateTransform(newTransform: simd_float4x4) {
        let arTransform = newTransform
        let arT = arTransform.columns.3
        let rosTx = -arT.z
        let rosTy = -arT.x // Use the reqranuired sign for the Y-axis
        let rosTz = arT.y
        var rosTransform = matrix_identity_float4x4
        rosTransform.columns.3 = simd_float4(rosTx, rosTy, rosTz, 1.0)
	    // Use this order:
	    let rosRotationMatrix = arTransform * rotationMatrix
        rosTransform.columns.0 = rosRotationMatrix.columns.0
        rosTransform.columns.1 = rosRotationMatrix.columns.1
        rosTransform.columns.2 = rosRotationMatrix.columns.2
        let rosTranslationVector = simd_float4(rosTx, rosTy, rosTz, 1.0)
            rosTransform.columns.3 = rosTranslationVector
            
            
            // --- 3. EXTRACT AND ASSIGN FINAL VALUES ---

            // The translation data is directly in the last column of the final rosTransform
            // (Corrected: You can use the rosTranslationVector for simplicity)
            let finalTranslation = rosTranslationVector
            
            self.x = Double(finalTranslation.x) // Use the calculated rosTx
            self.y = Double(finalTranslation.y) // Use the calculated rosTy
            self.z = Double(finalTranslation.z) // Use the calculated rosTz
            
            // Create the 3x3 rotation matrix from the top-left 3 columns of the final rosTransform
            // (Corrected: This block of code was misplaced and the structure was defined inside the matrix)
            let finalRotationMatrix = simd_float3x3(
                // Column 0
                simd_float3(rosTransform.columns.0.x, rosTransform.columns.0.y, rosTransform.columns.0.z),
                // Column 1
                simd_float3(rosTransform.columns.1.x, rosTransform.columns.1.y, rosTransform.columns.1.z),
                // Column 2
                simd_float3(rosTransform.columns.2.x, rosTransform.columns.2.y, rosTransform.columns.2.z)
            )
            
            let misalignedQuaternion = simd_quatf(finalRotationMatrix) // Store the quaternion
	    
			let rotationAngle = Float.pi / 2.0 // Use 90 degrees (1.5708 rad)
		   
		   // Create the quaternion for a rotation around the Z-axis
		   let correctionQuaternion = simd_quatf(angle: rotationAngle, axis: simd_float3(1, 1, 1))
		   
		   // Apply the correction: Correction * Misaligned
		   let correctedQuaternion = correctionQuaternion * misalignedQuaternion
		   
		   // Store the final result
		   self.quaternion = correctedQuaternion
        }
    
    
    override func constructPayload(frameTime: TimeInterval){
        let rosTime = self.convertTimestampToROS(timestamp: frameTime)
        let payload: [String: Any] = [
                "op": self.op,
                "topic": self.topic,
                "type": self.topicType,
                "msg": [
                    "header": [
                        "stamp": rosTime,
                        "frame_id": "odom" // The parent frame (fixed world)
                    ],
                    "child_frame_id": "base_link", // The moving frame (your camera/robot)
                    "transform": [
                        "translation": ["x": self.x, "y": self.y, "z": self.z],
                        "rotation": [
                            "x": -1 * Double(self.quaternion.vector.x),
                            "y": -1 * Double(self.quaternion.vector.y),
                            "z": Double(self.quaternion.vector.z),
                            "w": Double(self.quaternion.vector.w)
                        ]
                    ]
			 ],
			 "queue_length": 1
            ]
        self.msg = payload
    }
    

    
}


