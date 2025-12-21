//
//  ContentView.swift
//  iOSDepthToROS2
//
//  Created by Ayan Syed on 12/11/25.
//
import SwiftUI

//Home Screen UI

struct ContentView: View {
    var body: some View {
        TabView {
            // Tab 1: The Main AR View
            VStack {
                Text("Running ARKit Publisher")
                    .padding()
                CustomARViewContainer()
                    .ignoresSafeArea()
            }
            .tabItem {
                Label("AR Stream", systemImage: "arkit")
            }
            
            // Tab 2: The Settings View
            SettingsView()
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
    }
}
