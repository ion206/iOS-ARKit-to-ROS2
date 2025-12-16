Dependencies:
* StarScream WebSockets: https://github.com/daltoniam/Starscream

Developed and Tested on:
* iPhone 17 Pro Max (any iPhone w LIDAR should work)
* iOS 26
* MacOS 26 
* ROS2 Humble
* Ubuntu 22.04

ROS2 Launch and publisher topic Files:
To start receiving and convert topic and depthMap data:

Only need to run once: 
Set the python script to an executable

```chmod +x tf_broadcaster.py```



To Launch ROSbridge and all other nodes:

```ros2 launch arkitAdapter.launch.py```
