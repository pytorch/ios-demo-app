# D2Go Object Detection on iOS

## Introduction

[Detectron2](https://github.com/facebookresearch/detectron2) is one of the most widely adopted open source projects and implements state-of-the-art object detection, semantic segmentation, panoptic segmentation, and human pose prediction. [D2Go](https://github.com/facebookresearch/d2go) is powered by PyTorch 1.8, torchvision 0.9, and Detectron2 with built-in SOTA networks for mobile - the D2Go model is very small (only 2.7MB) and runs very fast on iOS.

This D2Go iOS demo app shows how to prepare and use the D2Go model on iOS. The code is based on a previous PyTorch iOS [Object Detection demo app](https://github.com/pytorch/ios-demo-app/tree/master/ObjectDetection) that uses a pre-trained YOLOv5 model, with modified pre-processing and post-processing code required by the D2Go model.

## Prerequisites

* PyTorch 1.8.1 and torchvision 0.9.1 (Optional)
* Python 3.8 or above (Optional)
* iOS cocoapods torchvision library
* Xcode 12.3 or later

## Quick Start

This section shows how to create and use the D2Go model in an iOS app. To just build and run the app without creating the D2Go model yourself, go directly to Step 4.

1. Install PyTorch 1.8.1 and torchvision 0.9.1, for example:

```
conda create -n d2go python=3.8.5
conda activate d2go
pip install torch torchvision
```

2. Install Detectron2, mobile_cv, and D2Go

```
python -m pip install 'git+https://github.com/facebookresearch/detectron2.git'
python -m pip install 'git+https://github.com/facebookresearch/mobile-vision.git'
git clone https://github.com/facebookresearch/d2go
cd d2go && python -m pip install .

```

3. Create the D2Go model

Run the following commands to create the quantized D2Go model:

```
git clone https://github.com/pytorch/ios-demo-app
cd ios-demo-app/D2Go
python create_d2go.py
```

The size of the quantized D2Go model is only 2.6MB.

4. Build and run the D2Go iOS app

If you have not gone through Step 3, simply run `git clone https://github.com/pytorch/ios-demo-app` first, then `cd ios-demo-app/D2Go`.

Run the commands below:

```
pod install
open D2Go.xcworkspace/
```

Select an iOS simulator or device on Xcode to run the app. You can go through the included example test images to see the detection results. You can also select a picture from your iOS device's Photos library, take a picture with the device camera, or even use live camera to do object detection - see this [video](https://drive.google.com/file/d/1GO2Ykfv5ut2Mfoc06Y3QUTFkS7407YA4/view) for a screencast of the app running.

Some example images and the detection results are as follows:

![](screenshot1.png)
![](screenshot2.png)

![](screenshot3.png)
![](screenshot4.png)
