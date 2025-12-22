//
//  OdometryPayload.swift
//  iOSDepthToROS2
//

import Foundation
import simd
import ARKit

///Handles topic type: nav_msgs/msg/Odometry
class OdometryPayload: Payload {
    let topicType: String = "Odometry/"
    let msgType: String = "Odometry"
	
    
    // Use your verified rotation matrix
    let rotationMatrix = simd_float4x4(
	   simd_float4( 0, 0, 1, 0),
	   simd_float4( 1, 0, 0, 0),
	   simd_float4( 0, 1, 0, 0),
	   simd_float4( 0, 0, 0, 1)
    )
    
    var x: Double = 0.0
    var y: Double = 0.0
    var z: Double = 0.0
    var quaternion: simd_quatf = simd_quatf()
	// Inside OdometryPayload class
	var linearVel = simd_float3(0, 0, 0)
	var angularVel = simd_float3(0, 0, 0)

    
    init(topicName: String) {
	   super.init(topicField: (self.topicType + topicName), msgType: self.msgType)
	   // Explicitly set the ROS message type for the bridge
	   self.type = "nav_msgs/msg/Odometry"
	   print("Created Odometry Topic Class: " + self.topic + " with Type: " + self.type)
    }
    
    func updateTransform(newTransform: simd_float4x4) {
	   let arTransform = newTransform
	   let arT = arTransform.columns.3
	   
	   // Use your verified translation logic
	   let rosTx = -arT.z
	   let rosTy = -arT.x
	   let rosTz = arT.y
	   
	   var rosTransform = matrix_identity_float4x4
	   let rosRotationMatrix = arTransform * rotationMatrix
	   
	   rosTransform.columns.0 = rosRotationMatrix.columns.0
	   rosTransform.columns.1 = rosRotationMatrix.columns.1
	   rosTransform.columns.2 = rosRotationMatrix.columns.2
	   
	   let rosTranslationVector = simd_float4(rosTx, rosTy, rosTz, 1.0)
	   rosTransform.columns.3 = rosTranslationVector
	   
	   self.x = Double(rosTranslationVector.x)
	   self.y = Double(rosTranslationVector.y)
	   self.z = Double(rosTranslationVector.z)
	   
	   let finalRotationMatrix = simd_float3x3(
		  simd_float3(rosTransform.columns.0.x, rosTransform.columns.0.y, rosTransform.columns.0.z),
		  simd_float3(rosTransform.columns.1.x, rosTransform.columns.1.y, rosTransform.columns.1.z),
		  simd_float3(rosTransform.columns.2.x, rosTransform.columns.2.y, rosTransform.columns.2.z)
	   )
	   
	   let misalignedQuaternion = simd_quatf(finalRotationMatrix)
	   
	   // Use your verified correction logic
	   let rotationAngle = Float.pi / 2.0
	   let correctionQuaternion = simd_quatf(angle: rotationAngle, axis: simd_float3(1, 1, 1))
	   
	    let resultQuat = (correctionQuaternion * misalignedQuaternion).normalized
	    self.quaternion = resultQuat
    }
	
	
	func updateTwist(linear: simd_float3, angular: simd_float3) {
	    self.linearVel = linear
	    self.angularVel = angular
	}

    
    override func constructPayload(frameTime: TimeInterval) {
	   let rosTime = self.convertTimestampToROS(timestamp: frameTime)
	   
	   // Odometry messages expect a 36-element covariance array (6x6 matrix)
	   // We initialize as an identity matrix with low variance or all zeros
	   let poseCovariance = Array(repeating: 0.0, count: 36)
	   let twistCovariance = Array(repeating: 0.0, count: 36)
	    
	    
	   
	   let payload: [String: Any] = [
		  "op": self.op,
		  "topic": self.topic,
		  "type": self.type,
		  "msg": [
			 "header": [
				"stamp": rosTime,
				"frame_id": "odom"
			 ],
			 "child_frame_id": "base_link",
			 "pose": [
				"pose": [
				    "position": ["x": self.x, "y": self.y, "z": self.z],
				    "orientation": [
					   "x": (-1 * Double(self.quaternion.vector.x)),
					   "y": (-1 * Double(self.quaternion.vector.y)),
					   "z": Double(self.quaternion.vector.z),
					   "w": Double(self.quaternion.vector.w)
				    ]
				],
				"covariance": poseCovariance
			 ],
			 "twist": [
				"twist": [
				    "linear": ["x": self.linearVel.x, "y": self.linearVel.y, "z": self.linearVel.z],
				    "angular": ["x": self.angularVel.x, "y": self.angularVel.y, "z": self.angularVel.z]
				],
				"covariance": twistCovariance
			 ]
		  ],
		  "queue_length": 1
	   ]
	   self.msg = payload
    }
}
