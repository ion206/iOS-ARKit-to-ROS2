//
//  DataExtractor.swift
//  iOSDepthToROS2
//
//  Created by Ayan Syed on 12/15/25.
//

import Foundation
import ARKit
import CoreVideo
import simd
import CoreMotion

//This File holds all helper functions to access AR Kit Data from ARFrames, ARDepthData, and more
//Turns Apple AR, Reality, and Motion intern data into Swift Data() objects that can be parsed, used, and converted into the formats we need for ROS2 and rosbridge


struct DataExtractor {
    // Converts an ARDepthData from ARKit Session into a raw Swift Data object

	static func extractRawDepthData(from depthData: ARDepthData) -> (data: Data, width: Int, height: Int) {
        // Get the CVPixelBuffer (The raw data container)
		let depthPixelBuffer = depthData.depthMap
        let width = CVPixelBufferGetWidth(depthPixelBuffer)
        let height = CVPixelBufferGetHeight(depthPixelBuffer)
        CVPixelBufferLockBaseAddress(depthPixelBuffer, .readOnly) //Lock the base address to access raw memory
        
        // Get a pointer to the start of the data
	    guard let baseAddress = CVPixelBufferGetBaseAddress(depthPixelBuffer) else {
		    CVPixelBufferUnlockBaseAddress(depthPixelBuffer, .readOnly)
		    return (Data(), width, height) //Return empty
	    }
        // Calculate the total size of the data in bytes - For 32-bit float (4 bytes) and 1 channel:
        // Total Size = Width * Height * 4 Bytes
        let totalBytes = width * height * MemoryLayout<Float32>.size
        // Create Swift Data object by copying the bytes into Data()
        let data = Data(bytes: baseAddress, count: totalBytes)
        CVPixelBufferUnlockBaseAddress(depthPixelBuffer, .readOnly) //Unlock the base address to release the memory lock
        return (data, width, height)
    }
	
	// Same inputs and outputs as normal Depth Data, but downscales the image by a factor of (scale) for less bytes
	static func extractDownscaledDepthData(from depthData: ARDepthData, scale: CGFloat = 0.75) -> (data: Data, width: Int, height: Int) {
	    let depthPixelBuffer = depthData.depthMap
	    let ciImage = CIImage(cvPixelBuffer: depthPixelBuffer)
	    
	    // Calculate the new dimensions
	    let originalWidth = CVPixelBufferGetWidth(depthPixelBuffer)
	    let originalHeight = CVPixelBufferGetHeight(depthPixelBuffer)
	    let newWidth = Int(CGFloat(originalWidth) * scale)
	    let newHeight = Int(CGFloat(originalHeight) * scale)
	    
	    // Apply the scaling transform
	    let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
	    
	    // Prepare the destination buffer (4 bytes per pixel for Float32)
	    let context = CIContext(options: [.useSoftwareRenderer: false])
	    let bytesPerPixel = MemoryLayout<Float32>.size
	    let rowBytes = newWidth * bytesPerPixel
	    let totalBytes = rowBytes * newHeight
	    
	    var data = Data(count: totalBytes)
	    
	    // Render to the Data object
	    data.withUnsafeMutableBytes { ptr in
		   if let baseAddress = ptr.baseAddress {
			  context.render(scaledImage,
						  toBitmap: baseAddress,
						  rowBytes: rowBytes,
						  bounds: CGRect(x: 0, y: 0, width: newWidth, height: newHeight),
						  format: .Rf, // Critical: R-channel Float (32-bit)
						  colorSpace: nil) // Depth is non-color data
		   }
	    }
	    
	    return (data, newWidth, newHeight)
	}
    
        
    // Converts the ARDepthData confidence map CVPixelBuffer into a raw Swift Data object.
    static func extractRawConfidenceData(from depthData: ARDepthData) -> (data: Data, width: Int, height: Int) {
        
        // SAFELY UNWRAP the confidenceMap
        guard let confidencePixelBuffer = depthData.confidenceMap else {
            return (Data(), 0, 0) // Return nil data and zero dimensions if the map is unavailable
        }
        // Now confidencePixelBuffer is guaranteed to be a non-optional CVPixelBuffer
        let width = CVPixelBufferGetWidth(confidencePixelBuffer)
        let height = CVPixelBufferGetHeight(confidencePixelBuffer)
        CVPixelBufferLockBaseAddress(confidencePixelBuffer, .readOnly) // Lock the base address
        // Get a pointer to the start of the data, and SAFELY UNWRAP it
        guard let baseAddress = CVPixelBufferGetBaseAddress(confidencePixelBuffer) else {
            CVPixelBufferUnlockBaseAddress(confidencePixelBuffer, .readOnly)
            return (Data(), width, height)
        }
        // Calculate the total size of the data in bytes
        let bytesPerRow = CVPixelBufferGetBytesPerRow(confidencePixelBuffer)
        let totalBytes = bytesPerRow * height
        let data = Data(bytes: baseAddress, count: totalBytes) // Create the Swift Data object by copying the bytes
        CVPixelBufferUnlockBaseAddress(confidencePixelBuffer, .readOnly) // Unlock the base address
        return (data, width, height)
    }
    
    // Gets the ARKit Calculated Transform of a given frame in time, relative to init point
    static func getPoseTransform(frame: ARFrame) -> simd_float4x4 {
        let arTransform = frame.camera.transform
        return arTransform
    }
    
	// Gets and calculates Camera Intrinsics info of a given AR Kit Frame - very necessary for calibration and SLAM use
    static func getCameraInfo(frame: ARFrame) -> (Int, Int, [Double]){
        let camera = frame.camera
        let resolution = camera.imageResolution
        let intrinsics = camera.intrinsics //simd_float3x3 matrix
		
        // Flatten the intrinsics matrix (focal length fx, fy, principal point cx, cy)
        // ROS K matrix is a 3x3 row-major array.
        // [fx, 0, cx, 0, fy, cy, 0, 0, 1]
        let K: [Double] = [
            // Row 0: fx, 0, cx
            Double(intrinsics[0][0]), Double(intrinsics[0][1]), Double(intrinsics[0][2]),
            // Row 1: 0, fy, cy
            Double(intrinsics[1][0]), Double(intrinsics[1][1]), Double(intrinsics[1][2]),
            // Row 2: 0, 0, 1
            Double(intrinsics[2][0]), Double(intrinsics[2][1]), Double(intrinsics[2][2])
        ]
        
        return (Int(resolution.width), Int(resolution.height), K)
    }
	
	
	
	// Persistent state for velocity calculation
	    private static var lastPosition: simd_float3?
	    private static var lastTimestamp: TimeInterval?
	// Initialize Motion Manager once
	    private static let motionManager = CMMotionManager()
	
	
	//These next two functions are used for /Odometry topics, using the linar/angular vel dead reckoning for positioning.
	//We can use CM Motion Manager here to simplify a ton of Swift Work. (Core Motion)
		static func startMotionUpdates() {
		   if motionManager.isDeviceMotionAvailable {
			  motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
			  motionManager.startDeviceMotionUpdates()
		   }
	    }
		
		//Twist is essentially velocities that we can use for various different alculations
		// Returns Linear and angular velocitiies in simd_float(s)
	    static func getTwist(frame: ARFrame) -> (linear: simd_float3, angular: simd_float3) {
		   let currentTime = frame.timestamp
		   let currentPos = simd_float3(frame.camera.transform.columns.3.x,
								  frame.camera.transform.columns.3.y,
								  frame.camera.transform.columns.3.z)
		   
		   var linearVelocity = simd_float3(0, 0, 0)
		   
		   // Calculate Linear Velocity (dx/dt)
		   if let lastPos = lastPosition, let lastTime = lastTimestamp {
			  let dt = Float(currentTime - lastTime)
			  if dt > 0 {
				 let deltaPos = currentPos - lastPos
				 let rawVelocity = deltaPos / dt
				 // Apply your working ROS coordinate shuffle
				 linearVelocity = simd_float3(-rawVelocity.z, -rawVelocity.x, rawVelocity.y)
			  }
		   }
		   
		   lastPosition = currentPos
		   lastTimestamp = currentTime
		   
		   // Get Angular Velocity Synchronously
		   var angularVelocity = simd_float3(0, 0, 0)
		   if let motion = motionManager.deviceMotion {
			  let rate = motion.rotationRate // CMRotationRate (x, y, z) in rad/s
			  
			  // Map to ROS axes based on your working rotation logic
			  angularVelocity = simd_float3(Float(rate.z), Float(rate.x), Float(rate.y))
		   }
		   
		   return (linearVelocity, angularVelocity)
	    }
	
	
	
	//For Getting Color Images. Apples AR Kit doesnt natively use RGB8 encoding, but thats the standard for ROS so we encode it to match that from a CV Pixel Buffer
	static func extractRGB8ImageData(from pixelBuffer: CVPixelBuffer) -> (data: Data, width: Int, height: Int) {
	    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
	    let context = CIContext()
	    
	    let width = CVPixelBufferGetWidth(pixelBuffer)
	    let height = CVPixelBufferGetHeight(pixelBuffer)
	    
	    // Create a buffer for the RGB data (3 bytes per pixel: R, G, B)
	    let bytesPerPixel = 3
	    let rgbDataSize = width * height * bytesPerPixel //Times Num of Pixels
	    var rgbData = Data(count: rgbDataSize)
	    
	    // Render the CIImage into the RGB buffer
	    // We specify a standard RGB color space
	    rgbData.withUnsafeMutableBytes { ptr in
		   if let baseAddress = ptr.baseAddress {
			  context.render(ciImage,
						  toBitmap: baseAddress,
						  rowBytes: width * bytesPerPixel,
						  bounds: ciImage.extent,
						  format: .RGBA8, // We render as RGBA then strip A, or use a custom filter
						  colorSpace: CGColorSpaceCreateDeviceRGB())
		   }
	    }
	    
	    // Note: CIContext.render for .RGBA8 produces 4 bytes per pixel.
	    // ROS "rgb8" expects exactly 3 bytes. Let's optimize:
	    
	    return (stripAlpha(from: rgbData, width: width, height: height), width, height)
	}

	// Helper to convert 4-byte RGBA to 3-byte RGB for ROS
	private static func stripAlpha(from rgbaData: Data, width: Int, height: Int) -> Data {
	    var rgbData = Data(capacity: width * height * 3)
	    rgbaData.withUnsafeBytes { ptr in
		   let rgbaPtr = ptr.bindMemory(to: UInt8.self)
		   for i in stride(from: 0, to: width * height * 4, by: 4) {
			  rgbData.append(rgbaPtr[i])     // R
			  rgbData.append(rgbaPtr[i + 1]) // G
			  rgbData.append(rgbaPtr[i + 2]) // B
		   }
	    }
	    return rgbData
	}
	
	// Like the above function but retursn downscale RGB8 color images. Downscaled by a factor of (scale)
	static func extractDownsampledRGB8Data(from pixelBuffer: CVPixelBuffer, scale: CGFloat = 0.1) -> (data: Data, width: Int, height: Int) {
	    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
	    
	    // Calculate new dimensions
	    let newWidth = Int(CGFloat(CVPixelBufferGetWidth(pixelBuffer)) * scale)
	    let newHeight = Int(CGFloat(CVPixelBufferGetHeight(pixelBuffer)) * scale)
	    
	    // Apply a scaling transform to the CIImage
	    let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
	    
	    let context = CIContext(options: [.useSoftwareRenderer: false])
	    let bytesPerPixel = 4 // Rendering to RGBA8 first
	    let rgbaDataSize = newWidth * newHeight * bytesPerPixel
	    var rgbaData = Data(count: rgbaDataSize)
	    
	    rgbaData.withUnsafeMutableBytes { ptr in
		   if let baseAddress = ptr.baseAddress {
			  context.render(scaledImage,
						  toBitmap: baseAddress,
						  rowBytes: newWidth * bytesPerPixel,
						  bounds: scaledImage.extent,
						  format: .RGBA8,
						  colorSpace: CGColorSpaceCreateDeviceRGB())
		   }
	    }
	    
	    // 3. Convert RGBA to RGB (Strip Alpha)
	    var rgbData = Data(capacity: newWidth * newHeight * 3)
	    rgbaData.withUnsafeBytes { ptr in
		   let rgbaPtr = ptr.bindMemory(to: UInt8.self)
		   for i in stride(from: 0, to: newWidth * newHeight * 4, by: 4) {
			  rgbData.append(rgbaPtr[i])     // R
			  rgbData.append(rgbaPtr[i + 1]) // G
			  rgbData.append(rgbaPtr[i + 2]) // B
		   }
	    }
	    
	    return (rgbData, newWidth, newHeight)
	}
	
	
		    
}
    
    
//Tried Implementing IMU, but i think its only for visionOS and just seems generally unsatble with all the jank methods I try to get it with
//Not completely necessary for my use case so will skip for now. But if somebody would like to share a consistently working iOS fix for this, feel free to make a PR!!

//    static func getIMUData(frame: ARFrame) -> (acc: simd_double3, rot: simd_double3) {
//        guard let motion = frame.camera.image. else { return (simd_double3(), simd_double3())}
//        let rotationRate = motion.rotationRate
//        let userAcceleration = motion.userAcceleration
//        return (userAcceleration, rotationRate)
//    }
