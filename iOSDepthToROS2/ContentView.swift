import SwiftUI
import RealityKit
import ARKit



struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Running App..")
        }
        .padding()
        CustomARViewContainer()
            .ignoresSafeArea()
    }
}
