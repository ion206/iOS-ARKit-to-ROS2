//
//  CustomARView.swift
//  iOSDepthToROS2
//
//  Created by Ayan Syed on 12/11/25.
//

import ARKit
import RealityKit
import SwiftUI
import CoreVideo

//AR View handles topic creation, data getting/updating, and uploading
//Basically the main controller of everything this app does!

// -- PARAMS --

//Enable/Disable Topics Manually
let enableDepthRaw = true // /arkit/Image/depth_raw
let enableImageRaw = true // /arkit/Image/image_raw
let enableConfidence = false // /arkit/Image/depth_confidence
let enablePoseTf = true // /arkit/Pose/pose_tf
let enableOdom = true // /arkit/Odometry/camera_odom
let enableCamInfo = true // /arkit/depth/camera_info


//Make sure this matches the scaling in the Image/Depth Downscaled Functions in DataExtractor.swift
let scaleFactor: CGFloat = 0.1 // 1440 * 0.25 = 360 - for the camera_info topic

let enableBSON = false //Currently have this as false, as rosbridge has BSON Serialization errors

// --------------



// Create a Payload Object for each topic
let depthTopic = ImagePayload(topicName: "depth_raw")
let imageTopic = ImagePayload(topicName: "image_raw", encoding: "rgb8")
let confidenceTopic = ImagePayload(topicName: "depth_confidence", encoding: "mono8")
let poseTfTopic = TransformStampedPayload(topicName: "pose_tf")
let odomTopic = OdometryPayload(topicName: "camera_odom")
let cameraInfoTopic = CameraInfoPayload(topicName: "camera_info")

// Make CustomARView conform to ARSessionDelegate
class CustomARView: ARView, ARSessionDelegate {
	
	//Core variables and Class Handlers
    private var activePayloads: [String : Payload] = [:] // Holds the Payloads that will be updated and sent
    private var websocket: WebSockets! // WebSocket Handler Class
	
	
	//For FPS and timestamp
    private var sessionTimeOffset: TimeInterval?
    private var lastPublishTime: TimeInterval = 0
    private var targetPublishInterval: TimeInterval = 1.0 / 10.0 // Default 10 FPS (0.1 seconds)
	
	//Other
	private let defaults = UserDefaults.standard
    
	
	//Constructor
    required init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
        session.delegate = self // Set the view's session delegate to itself
		
        // --- CONNECTION SETUP ---
        let rosHost = defaults.string(forKey: "ros_ip_address") ?? "XXX.XXX.X.XXX"
        self.websocket = WebSockets(ip: rosHost)
        
		
		
        // --- TOPIC ACTIVATION ---
        
		//What Topics to activate for updating and uploading
		//Active Payload keys correspond to topic names
		if enableDepthRaw {activePayloads["depth_raw"] = depthTopic}
		if enableCamInfo {activePayloads["camera_info"] = cameraInfoTopic}
		if enableImageRaw {activePayloads["image_raw"] = imageTopic}
		if enableConfidence {activePayloads["depth_confidence"] = confidenceTopic}
		if enablePoseTf {activePayloads["pose_tf"] = poseTfTopic}
		if enableOdom {activePayloads["camera_odom"] = odomTopic}
        
        //--- FPS SETUP ---
        let targetFPS = defaults.integer(forKey: "target_fps") // Will be 0 if unset, but Stepper starts at 1
        // Ensure you use a minimum FPS if the saved value is 0 or less
        let finalFPS = max(1, targetFPS)
        self.targetPublishInterval = 1.0 / TimeInterval(finalFPS)
        // 1. Set the onConnect closure to call advertise
        self.websocket.onConnect = { [weak self] in
            // Use a slight delay to ensure the WebSocket is fully ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                for payload in self?.activePayloads ?? [:] {
                    self?.websocket.advertiseTopic(payload: payload.value)
                }
            }
        }
	    
	    // Start Tracking Motion in Data Extractor
	    DataExtractor.startMotionUpdates()
    }
    
    dynamic required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implmented")
    }

    
    // This delegate method is called automatically every time the session updates a frame
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        let arFrameTime = frame.timestamp //This Frame's Timestamp
                
		// Skip this frame if it's too soon
		if (arFrameTime - lastPublishTime) < targetPublishInterval { return }
        
        // Calculate and store the offset on the first run
		// Needed becuase ROS Time is UNIX time while App time is from start of session
        if sessionTimeOffset == nil {
            // UNIX time now - AR time now = offset
            sessionTimeOffset = Date().timeIntervalSince1970 - arFrameTime
        }
        
        // Calculate the CORRECT UNIX Epoch time for the frame
        guard let offset = sessionTimeOffset else { return }
        
        let correctUnixEpochTime = offset + arFrameTime
		
		// --- UPDATE ACTIVATED TOPICS WITH RELEVANT INFO ---
        
        guard let sceneDepth = frame.sceneDepth else { return }
        if activePayloads["depth_raw"] != nil { //check if depth_raw is an activeTopic
            let (rawDepthData, width, height) = DataExtractor.extractDownscaledDepthData(from: sceneDepth)
            depthTopic.updateData(data: rawDepthData, height: height, width: width)
		   //print("h", height)
		   //print("w", width)
        }
		
        if activePayloads["depth_confidence"] != nil { //check if depth_confidence is an activeTopic
            let (rawData, width, height) = DataExtractor.extractRawConfidenceData(from: sceneDepth)
            confidenceTopic.updateData(data: rawData, height: height, width: width)
        }
        
        let imagePixelBuffer = frame.capturedImage // CVPixelBuffer
        if activePayloads["image_raw"] != nil { //check if image_raw is an activeTopic
            imageTopic.stepMultiplier = 3
            let (rawData, width, height) = DataExtractor.extractDownsampledRGB8Data(from: imagePixelBuffer)
            //print("Height: \(height), Width: \(width)")
            imageTopic.updateData(data: rawData, height: height, width: width)
        }
        
        if activePayloads["pose_tf"] != nil { //check if pose_tf is an activeTopic
            let newTf = DataExtractor.getPoseTransform(frame: frame)
            poseTfTopic.updateTransform(newTransform: newTf)
        }
	    
	    if activePayloads["camera_odom"] != nil { //check if camera_odom is an activeTopic
		    let newodom = DataExtractor.getTwist(frame: frame)
		    let newTf = DataExtractor.getPoseTransform(frame: frame)
		    odomTopic.updateTransform(newTransform: newTf)
		    odomTopic.updateTwist(linear: newodom.linear,angular: newodom.angular)
	    }
        
        if activePayloads["camera_info"] != nil { //check if pose_tf is an activeTopic
		   let (_, scaledW, scaledH) = DataExtractor.extractDownsampledRGB8Data(from: imagePixelBuffer, scale: scaleFactor)
		   // Update Camera Info with the SCALED values
		   cameraInfoTopic.updateResolution(height: scaledH, width: scaledW)
		   cameraInfoTopic.updateIntrinsics(matrix: frame.camera.intrinsics, scale: Double(scaleFactor))
        }
		
		
	    // Iterate through our active payloads and upload them to ros_bridge
		// We use JSON for smaller Data Uploading Topics and BSON for more heavier uploads like images becuase we can use Binary and smaller footprint
		//NOTE - upload BSON is broken rn so we are temp using JSON for everyhting
        for payload in activePayloads{
			if enableBSON && payload.value is ImagePayload {
				//BSON is currently quite unreliable on rosbridge's side so will keep this functionality for images here for the future
			   websocket.sendBSONString(bsonData: payload.value.getBSONPayload(frameTime: correctUnixEpochTime))
			}
			else{
			   websocket.sendJSONString(jsonString: payload.value.getPayload(frameTime: correctUnixEpochTime))
			}
        }
        
        lastPublishTime = arFrameTime
    }

    
    
    
}
