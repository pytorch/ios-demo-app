# PyTorchVideo Classification on iOS

## Introduction

The newly released open-sourced [PyTorchVideo](https://github.com/facebookresearch/pytorchvideo) adds video understanding to the rapidly growing PyTorch ecosystem. This PyTorchVideo Classification on iOS demo app shows how to use a pre-trained PyTorchVideo classification model on iOS to see video classification results, updated per second while the video plays, on tested videos, videos from the Photos library, or even real-time videos.

## Prerequisites

* PyTorch 1.9, torchvision 0.10, PyTorchVideo 0.1.1 (Optional)
* Python 3.8 or above (Optional)
* iOS Cocoapods LibTorch-Lite 1.9.0
* Xcode 12 or later


## Quick Start

### 1. Prepare the Model (Optional)

If you don't have the PyTorch environment set up to run the script, you can download the model file `video_classification.pt` [here](https://drive.google.com/file/d/1ti8Eb59L5BZV3YJa-c0AUx6XCgEvsqlV/view?usp=sharing) to the `ios-demo-app/TorchVideo/TorchVideo` folder, then skip the rest of this step and go to step 2 directly.

To create the model yourself, simply run the following commands:
```
conda create -n pt19 python=3.8.5
conda activate pt19
pip install torch torchvision
pip install pytorchvideo

# pip list|grep torch
# torch             1.9.0
# torchvision       0.10.0
# pytorchvideo      0.1.1

cd ios-demo-app/TorchVideo
python build_model.py

```
The model file `video_classification.pt` will be created and saved in the project folder.

### 2. Use LibTorch-Lite

Run the commands below:

```
pod install
open TorchVideo.xcworkspace/
```

### 3. Run the app

Select an iOS simulator or device on Xcode to run the app. You can go through the included example test images to see the detection results. You can also select a picture from your iOS device's Photos library, take a picture with the device camera, or even use live camera to do object detection - see this [video](https://drive.google.com/file/d/1ijb4UIuF2VQiab4xfAsBwrQXCInvb9wd/view) for a screencast of the app running.

Some screenshots of the video classification results are as follows:

![](screenshot1.png)
![](screenshot2.png)
![](screenshot3.png)
