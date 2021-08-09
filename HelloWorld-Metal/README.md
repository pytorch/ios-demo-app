### Requirements

- XCode 11.0 or above
- iOS 12.0 or above

## The HelloWorld-Metal Example

HelloWorld-Metal is a simple image classification application that demonstrates how to use PyTorch C++ libraries with Metal support. The code is written in Swift and uses Objective-C as a bridge.

### Model Preparation

The example has already attached a PyTorch GPU model in "HelloWorld-Metal/model/model.pt". If you would like to learn more about how to prepare a PyTorch GPU model and run it in your apps, please refer to the `Model Preparation` section in tutorial [(PROTOTYPE) USE IOS GPU IN PYTORCH](https://pytorch.org/tutorials/prototype/ios_gpu_workflow.html#model-preparation). 

### Install LibTorch-Lite-Nightly via Cocoapods

The PyTorch C++ library with Metal support is available in [Cocoapods](https://cocoapods.org/), to integrate it to our project, we can run

```ruby
pod install
```
Now open the `HelloWorld-Metal.xcworkspace` in XCode, select your device and launch it (cmd + R). If everything works well, we should see a wolf picture on the simulator screen along with the prediction results.

<img src="screenshot.png?raw=true" width="50%">
