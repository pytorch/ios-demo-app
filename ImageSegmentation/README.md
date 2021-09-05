# Semantic Image Segmentation DeepLabV3 with Mobile Interpreter on iOS

## Introduction

This repo offers a Python script that converts the [PyTorch DeepLabV3 model](https://pytorch.org/hub/pytorch_vision_deeplabv3_resnet101) to the Mobile Interpreter version and an iOS app that uses the model to segment images.

## Prerequisites

* PyTorch 1.9 and torchvision 0.10 (Optional)
* Python 3.8 or above (Optional)
* iOS Cocoapods LibTorch-Lite 1.9.0 and LibTorchvision 0.10.0
* Xcode 12.4 or later

## Quick Start

To Test Run the Image Segmentation iOS App, follow the steps below:

### 1. Prepare the Model

If you don't have the PyTorch environment set up to run the script below to generate the model file, you can download it to the `ios-demo-app/ImageSegmentation` folder using the link [here](https://drive.google.com/file/d/1_guNVutt8eTvO_YhGxkAe1uReBhNaC4f/view?usp=sharing).

Open a Mac Terminal, first install PyTorch 1.9 and torchvision 0.10 using command like `pip install torch torchvision`, then run the following commands:

```
git clone https://github.com/pytorch/ios-demo-app
cd ios-demo-app/ImageSegmentation
python deeplabv3.py
```

The Python script `deeplabv3.py` is used to generate the Lite Interpreter model file `deeplabv3_scripted.ptl` to be used in iOS.

### 2. Use LibTorch-Lite

Run the commands below (note the `Podfile` uses `pod 'LibTorch-Lite', '~>1.9.0'`):

```
pod install
open ImageSegmentation.xcworkspace/
```

### 3. Run the app
Select an iOS simulator or device on Xcode to run the app. The example image and its segmented result are as follows:

![](screenshot1.png)
![](screenshot2.png)

Note that the `resized` method in `UIImage+Helper.swift` is used to speed up the model inference, but a smaller size may cause the result to be less accurate.

## Tutorial

Read the tutorial [here](https://pytorch.org/tutorials/beginner/deeplabv3_on_ios.html) for detailed step-by-step instructions of how to prepare and run the [PyTorch DeepLabV3 model](https://pytorch.org/hub/pytorch_vision_deeplabv3_resnet101) on iOS, as well as practical tips on how to successfully use a pre-trained PyTorch model on iOS and avoid common pitfalls.

For more information on using Mobile Interpreter in Android, see the tutorial [here](https://pytorch.org/tutorials/recipes/mobile_interpreter.html).
