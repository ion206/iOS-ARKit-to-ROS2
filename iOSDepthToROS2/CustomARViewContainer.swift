//
//  CustomARViewContainer.swift
//  iOSDepthToROS2
//
//  Created by Ayan Syed on 12/11/25.
//
import SwiftUI
import RealityKit
import ARKit

// Holds the session and configuration externally from the constantly updating ARview

struct CustomARViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> CustomARView {
            print("Container Init and AR Session Starting...")
            let view = CustomARView(frame: .zero)
        let configuration = ARWorldTrackingConfiguration()
        if ARWorldTrackingConfiguration.supportsFrameSemantics([.sceneDepth]) {
            configuration.frameSemantics = [.sceneDepth]
        }

            view.session.run(configuration)
            return view
        }
    
    func updateUIView(_ uiView: CustomARView, context: Context) {
        // Not used for this simple case, but required by protocol
    }
}
