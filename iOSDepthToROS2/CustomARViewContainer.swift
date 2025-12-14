//
//  CustomARViewContainer.swift
//  iOSDepthToROS2
//
//  Created by Ayan Syed on 12/11/25.
//
import SwiftUI
import RealityKit
import ARKit

struct CustomARViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> CustomARView {
            print("Container Init and AR Session Starting...")
            let view = CustomARView(frame: .zero)
        let configuration = ARWorldTrackingConfiguration()
        if ARWorldTrackingConfiguration.supportsFrameSemantics([.sceneDepth, .smoothedSceneDepth]) {
            configuration.frameSemantics = [.sceneDepth, .smoothedSceneDepth]
        }
            
            // Note: If you plan to use depth, you must enable it here:
            // if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            //     config.frameSemantics = .sceneDepth
            // }

            view.session.run(configuration)
            
            // The call to print the initial frame state is no longer needed
            // print("Frame State!")
            // print(view.updateFrameState())
            
            return view
        }
    
    func updateUIView(_ uiView: CustomARView, context: Context) {
        // Not used for this simple case, but required by protocol
    }
}
