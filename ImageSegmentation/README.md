# Semantic Image Segmentation DeepLabV3 on iOS

## Introduction

This repo offers a Python script that converts the [PyTorch DeepLabV3 model](https://pytorch.org/hub/pytorch_vision_deeplabv3_resnet101) for mobile apps and an iOS app that uses the model to segment images.

## Quick Start

To Test Run the Image Segmentation iOS App, follow the steps below:

### 1. Prepare the Model

Open a Mac Terminal, run the following commands:

```
git clone https://github.com/pytorch/ios-demo-app
cd ios-demo-app/ImageSegmentation
python deeplabv3.py
```

The Python script `deeplabv3.py` is used to generate the TorchScript-formatted model for mobile apps. If you don't have the PyTorch environment set up to run the script, you can download the model file to the `ios-demo-app/ImageSegmentation` folder using the link [here](https://drive.google.com/file/d/17KeE6mKo67l14XxTl8a-NbtqwAvduVZG/view?usp=sharing).

Then run `mv deeplabv3_scripted.pt ImageSegmentation` to move the model file to the right location.

### 2. Use LibTorch

Run the commands below:

```
pod install
open ImageSegmentation.xcworkspace/
```

### 3. Run the app
Select an iOS simulator or device on Xcode to run the app. The example image and its segmented result are as follows:

results are:

![](screenshot1.png)
![](screenshot2.png)

Note that the example image used in the repo is pretty large (800x800) so the segmentation process may take over 30 seconds. Use either a smaller-sized image or call the `resized` method in `UIImage+Helper.swift` to speed up the inference (it takes about 1 second on an image of size 180*180).

## Tutorial

Read the tutorial [here](https://pytorch.org/tutorials/beginner/deeplabv3_on_ios.html) for detailed step-by-step instructions of how to prepare and run the [PyTorch DeepLabV3 model](https://pytorch.org/hub/pytorch_vision_deeplabv3_resnet101) on iOS, as well as practical tips on how to successfully use a pre-trained PyTorch model on iOS and avoid common pitfalls.
