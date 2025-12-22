# iOS ARKit-ROS2-Bridge
## By Ayan Syed
### Streaming iPhone Pro LiDAR and VIO Odometry to ROS 2

This repository provides a high-performance Swift bridge that transforms any iPhone Pro (or iPad Pro) into a sophisticated **RGB-D sensor and VSLAM unit** accessible by ROS 2. By leveraging the integrated **LiDAR scanner** and Apple's **Visual-Inertial Odometry (VIO) pipline**, this app streams real-time point clouds, depth maps, and high-frequency transform data directly to a ROS 2 workspace via `rosbridge`. This means that all topics can be streamed over any stable WiFi or Ethernet Connections

---

## 📱 Features
This app is designed specifically to exploit the hardware found in **iPhone Pro (12+)** models.

* **LiDAR-Powered Depth:** Streams 32-bit float depth maps (meters) synchronized with RGB frames.
* **VIO Odometry:** Publishes the iPhone's precise world-space position and orientation as `nav_msgs/Odometry` and `tf2`.
* **Real-time RGB:** Streams camera feed with configurable downscaling to optimize bandwidth.
* **JSON over WebSocket:** Uses a standard `rosbridge_suite` connection over JSON
* **6-DOF Tracking:** Leverages ARKit’s tracking to provide robust localization even in low-light or feature-poor environments.

---

## 📊 Published Topics

| Topic | Type | Description |
| --- | --- | --- |
| `/arkit/Image/image_raw` | `sensor_msgs/Image` | RGB Camera Feed |
| `/arkit/Image/depth_raw` | `sensor_msgs/Image` | 32FC1 LiDAR Depth Map |
| `/arkit/Odometry/camera_odom` | `nav_msgs/Odometry` | VIO-fused Pose Data |
| `/arkit/Pose/pose_tf` | `tf2_msgs/TFMessage` | Dynamic transforms (world -> camera) |
| `/arkit/depth/camera_info` | `sensor_msgs/msg/CameraInfo` | Live Camera Intrinsics |

---

## 🧬 How it Works: The Architecture

The app functions as a **WebSocket Client**. It encapsulates ARKit's sensor data into an Object-Oriented **Payload System**.

1. **Capture:** The app captures `ARFrame` data at 30-60Hz.
2. **Extraction:** Depth maps are extracted from the LiDAR buffer, and pose data is converted from ARKit’s Y-up coordinate system to the ROS **Right-Handed (Z-up)** system.
3. **Serialization:** Data is serialized into standard ROS-compatible JSON strings.
4. **WebSockets** Handled by StarScream WebSockets: (https://github.com/daltoniam/Starscream)
5. **Bridge:** The `rosbridge_server` on your Linux machine receives these JSONs and publishes them to the ROS 2 graph as native topics

---

### The LiDAR Scanner (dToF)

Unlike standard "Depth from Focus" or Stereo-Vision used in most cameras, the iPhone Pro uses **Direct Time-of-Flight (dToF)**. It emits nanosecond pulses of light to measure distance with centimeter-level precision up to 5 meters.

* **Precision:** Provides a dense, accurate depth map even on featureless surfaces like white walls.
* **Speed:** Operates at 60fps, allowing for rapid movement without the "motion blur" depth artifacts found in earlier sensors.

### Visual-Inertial Odometry (VIO)

The app exposes ARKit's fused **VIO** output. This combines high-frequency gyroscope/accelerometer data with visual feature tracking. The result is a highly stable `camera_odom` frame that serves as an excellent source for ROS 2 SLAM packages like **RTAB-Map** or **Nav2**. It has relocalization, error/drift correction, motion blur handling, and many more accuracy features already built in

---

## 🚀 Getting Started

### 1. Prerequisite: ROS 2 Setup

My Setup, just for reference:
* iPhone 17 Pro Max w iOS 26 (any iPhone w LIDAR should work)
* MacOS 26 (Mac Air M1)
* Ubuntu 22.04 w ROS2 Humble (Works with Normal Computer and through Docker Image) 


### 2. Configure the App
Apple allows "Personal Development" for free, meaning you don't need to pay the $99/year Developer Program fee just to run your code on your own hardware. Deploying your own Swift apps to your personal iPhone/iPad is a straightforward process, but it requires a specific set of steps to bypass the standard App Store submission.

**See DeployingiOSDeveloperApp.md**

### 3. Usage
On your ROS 2 machine (Humble/Jazzy), install and launch the `rosbridge_server`:

```bash
sudo apt update
source /opt/ros/[your ROS Distro]/setup.bash
sudo apt install ros-${ROS_DISTRO}-rosbridge-server
ros2 launch rosbridge_server rosbridge_websocket_launch.xml

```

1. Run the app on your iPhone/iPad Pro
2. The app should start sending data immediately, switch to settings to change the host IP, then restart the app for the settings to apply
3. Open a terminal on your ROS machine and verify the data stream:
```bash
ros2 topic hz /arkit/image_raw
ros2 topic echo /arkit/camera_odom

```
### Notes:
* Remember to always restart the App after changing any Settings
* Might be a good idea to keep the device plugged into power; the JSON encoding is quite taxing, and the battery may drain fast
* Always start Rosbridge Host before starting the app; otherwise, it won't connect
* By default, the port is set to 9090. To change the Port, you'll need to adjust `WebSockets.swift`, then redeploy

## Optimization
* Adjust upload FPS in settings to balance performance and topic frequency for your setup
* In `CustomARView.swift`, you can adjust the scale factor for images. Streaming 4K is not recommended over Wi-Fi; a scale of `0.5` or `0.25` is ideal for SLAM.
* For Bandwidth Purposes, enabled/disable topics from `CustomARView.swift`
---

### Release Notes
* This app has support for publishing images via BSON format for higher efficiency and performance; however, Rosbridge has been filled with BSON serialization errors. If those are fixed, feel free to spin up the BSON encoding functions for better battery life and topic Hz
* I also had some foundational work for getting an IMU topic publishing as well; however, there is a quite a mismatch between iOS vs VisionOS for this topic so I left it unimplmented right now

* If you have any fixes or ideas for this project, feel free to submit a PR, and I'd love to look it over!!
