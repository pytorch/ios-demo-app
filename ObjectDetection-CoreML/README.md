# Object Detection with PyTorch, Core ML, and Vision on iOS

<p align="center">
  <img src="https://user-images.githubusercontent.com/4254623/186172821-8fc8765b-bc86-4c31-ab44-b2e83d5d7646.PNG" align="center" height="500">
</p>

## Introduction
This demo app was built to showcase how to use PyTorch with Apple's Core ML. The app uses YOLOv5 as an example model.

[YOLOv5](https://github.com/ultralytics/yolov5) is a family of object detection models built with PyTorch. The models enable detecting objects from single images, where the model output includes predictions of bounding boxes, the bounding box classification, and the confidence of the prediction.


## Prerequisites

* Python >=3.7 
* Xcode

## Quick Start

### 1. Prepare the model

Start by cloning the repository and submodules:

```
git clone git@github.com:pytorch/ios-demo-app.git --recursive
cd ObjectDetection-CoreML
```


The Python script `export-nms.py` in the `yolov5` submodule folder is used to generate a Core ML -formatted YOLOv5 model. The script is a modified version of the original `export.py` script that includes the NMS at the end of the model to support using iOS's Vision.

Before running the script, create a python environment with python >=3.7 and install dependencies both in `requirements.txt` and `requirements-export.txt` with:

`pip install -r requirements.txt -r requirements-export.txt`.

To export the model, navigate to the `yolov5` directory and run:

`python export-nms.py --include coreml --weights yolov5n.pt` (The example app uses the nano-variant of the model)`

Note that the export has been tested with `python==3.7.13`, the dependecies in the `requirements` files and the specific commit of the included `yolov5` submodule.


### 2. Run the app

Navigate to the root of the `ObjectDetection-CoreML` directory and open the project with:

`open ObjectDetection-CoreML.xcodeproj`

The created `yolov5n.mlmodel` file in the `yolov5` directory needs to be dragged into the Xcode project files. Make sure to include the model in the target:

<img width="728" alt="Screenshot 2022-08-23 at 16 33 51" src="https://user-images.githubusercontent.com/4254623/186171710-bd66207a-c033-4ffc-965a-f0e92b4f4794.png">

Result:

<img width="272" alt="Screenshot 2022-08-23 at 16 16 44" src="https://user-images.githubusercontent.com/4254623/186167846-65da530a-0c6f-4cf2-9610-77093163d5f4.png">

Select an iOS simulator or device on Xcode to run the app. The app will start outputting predictions and the current inference time:

<p align="center">
  <img src="https://user-images.githubusercontent.com/4254623/186172821-8fc8765b-bc86-4c31-ab44-b2e83d5d7646.PNG" align="center" height="500">
</p>
