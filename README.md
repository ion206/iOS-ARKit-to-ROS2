Dependencies:
* StarScream WebSockets: https://github.com/daltoniam/Starscream

Developed and Tested on:
* iPhone 17 Pro Max (any iPhone w LIDAR should work)
* iOS 26
* MacOS 26 
* ROS2 Humble
* Ubuntu 22.04

ROS2 Launch and publisher topic Files:
To start receiving and convert topics


#Intial Setup Commands, working off a humble base image
apt update && apt install ros-humble-rosbridge-suite
source /opt/ros/humble/setup.bash
ros2 launch rosbridge_server rosbridge_websocket_launch.xml

sudo apt install ros-$ROS_DISTRO-foxglove-bridge
ros2 launch foxglove_bridge foxglove_bridge_launch.xml port:=8765


Foxglove Port: 8765
RosBridge Port : 9090
