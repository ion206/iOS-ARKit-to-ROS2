//
//  SettingsView.swift
//  iOSDepthToROS2
//
//  Created by Ayan Syed on 12/15/25.
//


//Holds the UI for selecting setting
//Note that when updating settings, you will need to restart the app for settings to take effect

//Settings that can be altered
//	IP Address: IP of the host websocket, the ROS2 Machine running the ros_bridge server
//	Topic Depth and Image Data - Activate/Deactivates
// 	Odometry Pose Data - Activate/Deactivate
// 	Upload FPS (Hz) (Frames being sent per sec)

import SwiftUI

struct SettingsView: View {
    // 1. IP Address
    @AppStorage("ros_ip_address") private var rosIpAddress: String = "XXX.XXX.X.XXX"
    
    // 2. Topic Toggles
    @AppStorage("topic_depth") private var isDepthActive: Bool = true
    @AppStorage("topic_pose") private var isPoseActive: Bool = true

    // 3. Optional: Throttling Rate
    @AppStorage("target_fps") private var targetFPS: Int = 10 // Default to 10 FPS

    var body: some View {
        NavigationView {
            Form {
                // --- A. Connection Settings ---
                Section(header: Text("ROS Bridge Connection")) {
                    TextField("IP Address (e.g., 192.168.x.x)", text: $rosIpAddress)
                        .keyboardType(.numbersAndPunctuation)
                        .autocapitalization(.none)
                }

                // --- B. Topic Selection ---
                Section(header: Text("Data Streams (Energy Impact)")) {
                    Toggle("Depth, Confidence, & Camera Info", isOn: $isDepthActive)
                        .tint(.red)
                    Toggle("Camera Pose (Odometry)", isOn: $isPoseActive)
                        .tint(.orange)
                }
                
                // --- C. Publishing Rate ---
                Section(header: Text("Publishing Rate")) {
                    Stepper("Target FPS: \(targetFPS) Hz", value: $targetFPS, in: 1...20)
                        .onChange(of: targetFPS) { newValue in
                            // Ensure the FPS value is updated in UserDefaults instantly
                            UserDefaults.standard.set(newValue, forKey: "target_fps")
                        }
                    Text("Lower FPS saves significant battery life.")
                        .font(.caption)
                }
            }
            .navigationTitle("Configuration")
        }
    }
}
