### Requirements

- XCode 11.0 or above
- iOS 12.0 or above

## The HelloWorld Example

HelloWorld is a simple image classification application that demonstrates how to use PyTorch C++ libraries on iOS. The code is written in Swift and uses Objective-C as a bridge.

### Model Preparation

The model we are going to use is [MobileNet v2](https://pytorch.org/hub/pytorch_vision_mobilenet_v2/), a pre-trained image classification model that has been packaged in [TorchVision](https://pytorch.org/docs/stable/torchvision/index.html). To install it, run the command below.

> We highly recommend following the [Pytorch Github page](https://github.com/pytorch/pytorch) to set up the Python development environment on your local machine.

```shell
pip install torchvision
```

Once we have TorchVision installed successfully, navigate to the HelloWorld folder and run `trace_model.py` to generate our model. The script contains the code of tracing and saving a [torchscript model](https://pytorch.org/tutorials/beginner/Intro_to_TorchScript_tutorial.html) that can be run on mobile devices.

```shell
python trace_model.py
```

If everything works well, `model.pt` should be generated in the `HelloWorld` folder. Now copy the model file to our application folder `HelloWorld/model`.

### Install LibTorch via Cocoapods

The PyTorch C++ library is available in [Cocoapods](https://cocoapods.org/), to integrate it to our project, we can run

```ruby
pod install
```
Now open the `HelloWorld.xcworkspace` in XCode, select an iOS simulator and launch it (cmd + R). If everything works well, we should see a wolf picture on the simulator screen along with the prediction results.

<img src="https://github.com/pytorch/ios-demo-app/blob/master/HelloWorld/screenshot.png?raw=true" width="50%">
