# Semantic Image Segmentation DeepLabV3 with Mobile Interpreter on iOS

## Introduction

This repo offers a Python script that converts the [PyTorch DeepLabV3 model](https://pytorch.org/hub/pytorch_vision_deeplabv3_resnet101) to the Mobile Interpreter version and an iOS app that uses the model to segment images.

## Prerequisites

* PyTorch 1.9.0 and torchvision 0.10.0 (Optional)
* Python 3.8 or above (Optional)
* iOS Cocoapods LibTorch-Lite 1.9.0
* Xcode 12.4 or later

## Quick Start

To Test Run the Image Segmentation iOS App, follow the steps below:

### 1. Prepare the Model

If you don't have the PyTorch environment set up to run the script below to generate the model file, you can download it to the `ios-demo-app/ImageSegmentation` folder using the link [here](https://drive.google.com/file/d/1FHV9tN6-e3EWUgM_K3YvDoRLPBj7NHXO/view?usp=sharing).

Be aware that the downloadable model file was created with PyTorch 1.7.0, matching the iOS LibTorch library 1.7.0 specified in the `Podfile`. If you use a different version of PyTorch to create your model by following the instructions below, make sure you specify the same iOS LibTorch version in the `Podfile` to avoid possible errors caused by the version mismatch. Furthermore, if you want to use the latest prototype features in the PyTorch master branch to create the model, follow the steps at [Building PyTorch iOS Libraries from Source](https://pytorch.org/mobile/ios/#build-pytorch-ios-libraries-from-source) on how to use the model in iOS.

Open a Mac Terminal, first install PyTorch 1.9.0 and torchvision 0.10.0 using command like `pip install torch torchvision`, then run the following commands:

```
git clone https://github.com/pytorch/ios-demo-app
cd ios-demo-app/ImageSegmentation
python deeplabv3.py
```

The Python script `deeplabv3.py` is used to generate the Lite Interpreter model file `deeplabv3_scripted.ptl` to be used in iOS.

### 2. Use LibTorch

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
