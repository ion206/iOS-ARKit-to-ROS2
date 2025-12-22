import Foundation
import simd


///Handles topic type: sensor_msgs/msg/CameraInfo
class CameraInfoPayload: Payload {
    let topicType: String = "depth/"
    let msgType: String = "CameraInfo"
    
    var distortion_model: String = "plumb_bob"
    var height: Int = 0
    var width: Int = 0
    
    // Intrinsic components
    var fx: Double = 0.0
    var fy: Double = 0.0
    var cx: Double = 0.0
    var cy: Double = 0.0
    
    init(topicName: String) {
	   super.init(topicField: (self.topicType + topicName), msgType: self.msgType)
	   self.type = "sensor_msgs/msg/CameraInfo"
		print("Created CameraInfo Topic Class: " + self.topic + " with Type: " + self.type)
    }

    // Pass the ALREADY SCALED height and width here
    func updateResolution(height: Int, width: Int) {
	   self.height = height
	   self.width = width
    }
    
    // Pass raw intrinsics and the scale factor used for the image
    func updateIntrinsics(matrix: simd_float3x3, scale: Double) {
	   self.fx = Double(matrix[0,0]) * scale
	   self.fy = Double(matrix[1,1]) * scale
	   self.cx = Double(matrix[2,0]) * scale
	   self.cy = Double(matrix[2,1]) * scale
    }
    
    override func constructPayload(frameTime: TimeInterval) {
	   let rosTime = self.convertTimestampToROS(timestamp: frameTime)
	   
	   // K: Intrinsic camera matrix
	   let K = [
		  fx,  0.0, cx,
		  0.0, fy,  cy,
		  0.0, 0.0, 1.0
	   ]
	   
	   // R: Rectification matrix (Identity for single camera)
	   let R = [1.0, 0.0, 0.0,
			  0.0, 1.0, 0.0,
			  0.0, 0.0, 1.0]
	   
	   // P: Projection matrix (3x4)
	   let P = [
		  fx,  0.0, cx,  0.0,
		  0.0, fy,  cy,  0.0,
		  0.0, 0.0, 1.0, 0.0
	   ]

	   let payload: [String: Any] = [
		  "op": self.op,
		  "topic": self.topic,
		  "type": self.type,
		  "msg": [
			 "header": ["stamp": rosTime, "frame_id": "camera_depth_frame"],
			 "height": self.height,
			 "width": self.width,
			 "distortion_model": self.distortion_model,
			 "d": [0.0, 0.0, 0.0, 0.0, 0.0], // ARKit is already rectified
			 "k": K,
			 "r": R,
			 "p": P
		  ],
		  "queue_length": 1
	   ]
	   self.msg = payload
    }
}
