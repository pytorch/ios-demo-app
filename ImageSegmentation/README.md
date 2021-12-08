# Semantic Image Segmentation DeepLabV3 with Mobile Interpreter on iOS

## Introduction

This repo offers a Python script that converts the [PyTorch DeepLabV3 model](https://pytorch.org/hub/pytorch_vision_deeplabv3_resnet101) to both the Full JIT and the Lite/Mobile Interpreter versions and an iOS app that uses the Full JIT model to segment images. Steps of how to prepare the Lite model and make the code changes in the Xcode project to use the Lite model are also provided.

## Prerequisites

* PyTorch 1.10 and torchvision 0.11 (Optional)
* Python 3.8 or above (Optional)
* iOS Cocoapods LibTorch 1.10.0 or LibTorch-Lite 1.10.0
* Xcode 12.4 or later

## Quick Start

To Test Run the Image Segmentation iOS App, follow the steps below:

### 1. Prepare the Model

If you don't have the PyTorch environment set up to run the script below to generate the full JIT model file, you can download it to the `ios-demo-app/ImageSegmentation` folder using the link [here](https://pytorch-mobile-demo-apps.s3.us-east-2.amazonaws.com/deeplabv3_scripted.pt).

Open a Terminal, first install PyTorch 1.10 and torchvision 0.11 using command like `pip install torch torchvision`, then run the following commands:

```
git clone https://github.com/pytorch/ios-demo-app
cd ios-demo-app/ImageSegmentation
python deeplabv3.py
```

The Python script `deeplabv3.py` is used to generate both the full JIT and the Lite Interpreter model files `deeplabv3_scripted.pt` and `deeplabv3_scripted.ptl` to be used in iOS.

### 2. Use LibTorch

Run the commands below (note the `Podfile` uses `pod 'LibTorch', '~>1.10.0'`):

```
pod install
open ImageSegmentation.xcworkspace
```

### 3. Run the app
Select an iOS simulator or device on Xcode to run the app. The example image and its segmented result are as follows:

![](screenshot1.png)
![](screenshot2.png)

Note that the `resized` method in `UIImage+Helper.swift` is used to speed up the model inference, but a smaller size may cause the result to be less accurate.

## Using the Lite/Mobile Interpreter Model

All the other iOS demo apps have been converted to use the new Mobile Interpreter model, except this Image Segmentation demo app, which is used to illustrate how to convert a demo using a full JIT model to one using the mobile interpreter model, by following 3 simple steps.

### 1. Prepare the Lite model

If you don't have the PyTorch environment set up to run the script `deeplabv3.py` to generate the mobile interpreter model file, you can download it to the `ios-demo-app/ImageSegmentation` folder using the link [here](https://pytorch-mobile-demo-apps.s3.us-east-2.amazonaws.com/deeplabv3_scripted.ptl). Otherwise, or if you prefer to run the script to generate the model yourself, just run `python deeplabv3.py`.

Note that to save a model in the mobile interpreter format, simply call `_save_for_lite_interpreter`, as shown at the end of the `deeplabv3.py`:
```
optimized_model.save("ImageSegmentation/deeplabv3_scripted.pt")
optimized_model._save_for_lite_interpreter("ImageSegmentation/deeplabv3_scripted.ptl")
```

### 2. Modify the Podfile

If you already went through the previous section and have the demo using the full JIT model up and running, close Xcode, go to the `ios-demo-app/ImageSegmentation` directory and run `pod deintegrate` first.

In `Podfile`, change `pod 'LibTorch', '~>1.10.0'` to `pod 'LibTorch-Lite', '~>1.10.0'`

Then run `pod install` and `open ImageSegmentation.xcworkspace`. Don't forget to drag and drop the `deeplabv3_scripted.ptl` file from step 1 to the project.

### 3. Change the iOS code

In `TorchModule.mm`, make the following changes:
* Change `#import <LibTorch/LibTorch.h>` to `#import <Libtorch-Lite/Libtorch-Lite.h>`
* Change `@protected torch::jit::script::Module _impl;` to `@protected torch::jit::mobile::Module _impl;`
* Change `_impl = torch::jit::load(filePath.UTF8String);` to `_impl = torch::jit::_load_for_mobile(filePath.UTF8String);`
* Delete `_impl.eval();`

Finally, in ViewController.swift, modify `pt` in `Bundle.main.path(forResource: "deeplabv3_scripted", ofType: "pt")` to `ptl`.

Now you can build and run the app using the Lite/Mobile interpreter model.

## Tutorial

Read the tutorial [here](https://pytorch.org/tutorials/beginner/deeplabv3_on_ios.html) for detailed step-by-step instructions of how to prepare and run the [PyTorch DeepLabV3 model](https://pytorch.org/hub/pytorch_vision_deeplabv3_resnet101) on iOS, as well as practical tips on how to successfully use a pre-trained PyTorch model on iOS and avoid common pitfalls.

For more information on using Mobile Interpreter in Android, see the tutorial [here](https://pytorch.org/tutorials/recipes/mobile_interpreter.html).
