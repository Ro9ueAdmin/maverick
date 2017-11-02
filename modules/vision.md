# Vision Module
Vision is an important (and fun) part of UAVs.  Maverick contains good basic support for the standard elements of Computer Vision and Video functionality:

- [**Gstreamer**](/modules/vision#gstreamer): Industry standard software for capturing, transcoding and transmitting video
- [**OpenCV**](/modules/vision#opencv): Industry standard software for Computer Vision
- **Aruco**: Fiducial Tag library, for recognising tags/markers in video
- [**Visiond**](/modules/vision#visiond): A dynamic service that detects camera and encoding hardware, and automatically generates a gstreamer pipeline to transmit the video over the network - eg. wifi.  Very useful for FPV, it will in the future be useful for transmitting CV and other video
- [**Vision_seek**](/modules/vision#vision_seek): Similar to visiond, a daemon for streaming/saving video stream from a Seek Thermal imaging device.
- [**Vision_landing**](/modules/vision#vision_landing): Software that uses tags/markers (Aruco) as landing patterns, and controls Precision Landing in ArduCopter
- [**Camera-streaming-daemon**](/modules/vision#camera-streaming-daemon): RTSP Video server with service discovery publishing.
- [**Wifibroadcast**](/modules/vision#wifibroadcast): Innovative software that uses monitor/inject mode of compatible wifi adapters to provide connection-less wifi video with graceful degradation, similar to traditional analogue FPV.
- [**Collision-avoidance-library**](/modules/vision#collision-avoidance-library): Intel RealSense Collision Avoidance Library is a library/tool for investigating collision avoidance strategies.  It uses Intel RealSense cameras for depth perception and allows different detection methods and avoidance strategies.
- [**Orb_Slam2**](/modules/vision#orb_slam2): Fast library for performing monocular and stereo SLAM
- [**RTAB-Map**](/modules/vision#rtab-map): RGB-D Graph-Based SLAM

One key advantage of Maverick is that wherever possible it provides the same versions of software across all platforms.  This is very useful for porting code and functionality across platforms, as the underlying components often vary widely in their APIs/features.  As of Maverick 1.0, the component versions are:  
- Gstreamer: **1.10.4**
- OpenCV: **3.2**
- ROS: **Kinetic**  

There are a few exceptions, eg. Raspberry gstreamer has extensive modifications made to support the Raspberry VPU that handles the hardware video encoding so this platform is stuck with a very old version of gstreamer (1.4).

### Gstreamer
Apart from the Raspberry platform as mentioned above, Gstreamer is a set version compiled from source on all platforms.  It includes certain optimizations and extra modules where appropriate for the platform - relevant hardware encoding modules for Odroid and Joule platforms.

The standard source-compiled gstreamer is installed into ~/software/gstreamer, and the necessary supporting environment is automatically set.  All other standard source-compiled Maverick software components such as OpenCV, ROS, Aruco, visiond, vision_landing etc all use this version of gstreamer.

It is possible to set the version of gstreamer in a localconf parameter (note this requires clearing the gstreamer install flag and waiting for a recompile, which can take several hours):  
`"maverick_vision::gstreamer::gstreamer_version": "1.12.0"`  
It is possible to install gstreamer from system packages by setting localconf parameter:  
`"maverick_vision::gstreamer::gstreamer_installtype": "native"`  

### OpenCV
Like gstreamer, OpenCV is compiled from source for a consistent version across all platforms.  Most current OS distributions provide the elderly OpenCV2.  OpenCV3 is a major release with many improvements and new features, Maverick provides the first stable release - 3.2.0.  This version can be changed by setting localconf parameter:  
`"maverick_vision::opencv::opencv_version": "3.x.x"`  
Note that OpenCV takes a **long** time to compile on slower platforms (6 hours+ on a Raspberry).  Opencv-contrib is included as standard, this can be disabled during compile by setting localconf parameter:  
`"maverick_vision::opencv::contrib": false`  
There are two compile options which rarely need to be changed:  
 - `"maverick_vision::opencv::release": "Release"` can be changed to 'Debug' to produced debug libraries/binaries
 - `"maverick_vision::opencv::precompile_headers": false'` control how the compile process uses precompile to speed up compilation.  However, it uses vast amounts of disk space so is turned off by default in Maverick

OpenCV is installed into ~/software/opencv and the necessary supporting environment is automatically set.

### Visiond
Visiond is a Maverick-specific (python-based) daemon that automates the process of capturing, transcoding and transmitting video over the network.  It detects the attached camera and encoding hardware and constructs a gstreamer pipeline based on the detected hardware details.  There is a dynamic config file in ~/data/config/vision/maverick-visiond.conf that allows easy configuration of the device, video format, resolution, framerate and network output.  To activate the config changes, restart the service:  
`maverick restart visiond`
This service is started by default.

### Vision_seek
Vision_seek is a service similar to visiond, for the Seek Thermal Compact and CompactPro thermal image cameras.  It captures the thermal data, transcodes and processes the data into a format suitable for visualisation, and then streams or saves the images or video to the network or file.  A nice simple setup is to plug the Seek camera directly into the USB port of a Raspberry Pi Zero (W).  
<img src="media/seekthermal-pic.jpg" width="100%">
There is a config file in ~/data/config/vision/vision_seek.conf that allows a simple way to alter settings - to activate the changes,  restart the service:  
`maverick restart vision_seek`  
This service is not started by default.  To start it:  
`maverick start vision_seek`  
To enable it by default on boot, set a localconf parameter:  
`"maverick_vision::vision_seek::active": true`  
Note that the hardware support for the Seek Thermal camera is automatically applied during a configure run if the camera is plugged in and detected.  To force this support to be installed if building a platform that the Seek is likely to be used with, refer to the [hardware documentation for Seek Thermal devices](/modules/hardware#seek-thermal-cameras).  

Image of lunch, without dead pixel correction applied:  
<img src="media/thermal-lunch.jpg" width="50%">

Image of Intel Joule before and after some hard work (running Maverick vision_landing):  
<img src="media/joule-thermal.jpg" width="50%">  

#### Flat Field Correction (FFC)  
To create an FFC image that can be applied to vision_seek to improve image quality, first run the camera for a while to warm it up, then cover the lens with something thermally consistent (eg. a book, or DVD cover) and run:  
`~/software/libseek-thermal/bin/seek_create_flat_field -c seek ~/data/config/vision/seek_ffc.png`  
Then set the *FFC* setting in *~/data/config/vision/vision_seek.conf* to point to this file:  
`FFC=/srv/maverick/data/config/vision/seek_ffc.png`  
If FFC is set in the config file, vision_seek will automatically apply it.  
More information about this FFC procedure can be found in the github project of the main supporting library behind vision_seek:  
https://github.com/maartenvds/libseek-thermal
#### Output
Vision_seek has three methods of output, all controlled by setting the *OUTPUT* parameter in the *~/data/config/vision/vision_seek.conf* config file.
 - _window_: This outputs to a local window.  This will not work when running vision_seek as a service, as the service is disconnected from any terminal and does not know where to create the window.  Instead, run `vision_seek.sh` from the command line, either logged into the desktop or through ssh with X-forwarding enabled (*ssh -X* or *ssh -Y*).
 - _filename.avi_: This outputs a raw video file to specified filename/path.  Raw video files can be very large but because of the relatively low resolution of the Seek devices this should not be a problem.
 - _appsrc gstreamer pipeline_: It is also possible to specify a gstreamer pipeline - _Note: the pipeline must start with 'appsrc ! '_.  This can be very useful for compressing the video, transcoding or converting the video format, or streaming over the network.  Several examples are given in the config file.

### Vision_landing
vision_landing combines the Aruco, Gstreamer, OpenCV and optionally RealSense components to create a system that analyses video in realtime for landing markers (Aruco/April fiducial markers, or tags) and uses these markers to estimate the position and distance of the landing marker compared to the UAV and passes this data to the flight controller to achieve Precision Landing.  The flight controller applies corrections according to the attitude of the UAV to work out what needs to be done to land directly on the marker.  A well tuned setup can achieve reliable accuracy to within a couple of centimeters.  

<img src="media/precland1.png" width="100%">

It is a work in progress (as is the support for vision based landing in ArduPilot) - the main project page is https://github.com/fnoop/vision_landing.

Like visiond, it has a dynamic config in ~/data/config/vision/vision_landing.conf, and to activate any config changes, restart the service:  
`maverick restart vision_landing`  
This service is not started by default, as it contends for camera usage with visiond.  To use it, first turn off visiond (`maverick stop visiond`).  It can be started a boot by setting a localconf parameter:  
`"maverick_vision::vision_landing::active": true`  

### Camera-streaming-daemon
camera-streaming-daemon is an open-source project from Intel (https://github.com/01org/camera-streaming-daemon).  It is still early stages for the project, but it has great promise for an improvement in the method that realtime digital video is normally implemented on UAVs.  Instead of the normal method of providing a gstreamer pipeline and endpoint to send data to, camera-streaming-daemon (csd) provides an RTSP server with multiple endpoints to connect to if there are multiple cameras or streams available, and publishes these streams over the network using Zeroconf/Avahi.  
camera-streaming-daemon is not yet the default over visiond (although it is intended to be when more mature), so it can be started simply by calling the csd service (after stopping visiond, which would contend for the video resource):  
`maverick stop visiond`  
`maverick start csd`  
To start at boot, set a localconf parameter:  
`"maverick_vision::camera_streaming_daemon::active": true`  

### Collision-avoidance-library
Intel RealSense Collision Avoidance Library is a library/tool for investigating collision avoidance strategies.  It uses Intel RealSense cameras for depth perception and allows different detection methods and avoidance strategies.  It is not intended to be an end-user service but more a system for developers to investigate collision avoidance.  Further information can be found here:  
https://github.com/01org/collision-avoidance-library/wiki  
Maverick provides collision-avoidance-library as a pre-installed and pre-configured vision component in the OS images.  It is not installed by default when building Maverick from scratch, to install it set a localconf parameter:  
`"maverick_vision::collision_avoidance": true`  
The coav-tool is controlled by maverick service *coav*, so to start and stop the service:  
`maverick start coav`  
`maverick stop coav`  
To configure it, alter configuration file *~/data/config/vision/coav.conf* and restart to activate the changes: `maverick restart coav`.  

### Orb_slam2
Orb_slam2 is installed and configured as part of the OS images, but is not installed by default when building Maverick from scratch, as it takes a lot of resource and is really an experimental/academic project - of limited real-world use.  To enable it, set localconf parameter:  
`"maverick_vision::orb_slam2": true`  

### RTAB-Map
Like Orb_slam2, RTAB-Map is installed as part of the OS images, but is not installed by default when building Maverick from scratch as it takes a lot of resource to compile and install.  To enable it, set localconf parameter:  
`"maverick_vision::rtabmap": true`  

### CUAV
CUAV is an image processing module for MAVProxy.  It is installed by default.  For more information, please see the [official documentation](http://canberrauav.github.io/cuav/build/html/index.html).