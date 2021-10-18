### Requirements

- XCode 12.5 or above
- iOS 14.0 or above

## The HelloWorld-CoreML Example

HelloWorld-CoreML is a simple image classification application that demonstrates how to use PyTorch C++ libraries with Core ML support. The code is written in Swift and uses Objective-C as a bridge.

The example has already attached a PyTorch GPU model in "HelloWorld-CoreML/model/mobilenetv2_coreml.pt". If you would like to learn more about how to prepare a PyTorch CoreML model and run it in your apps, please refer to the tutorial [Convert Mobilenetv2 to Core ML](https://pytorch.org/tutorials/prototype/ios_coreml_workflow.html). 

### Install LibTorch-Lite-Nightly via Cocoapods

The PyTorch C++ library with Core ML support is available in [Cocoapods](https://cocoapods.org/), to integrate it to our project, we can run

```ruby
pod update
```
Now open the `HelloWorld.xcworkspace` in XCode, select your device and launch it (cmd + R). If everything works well, we should see a wolf picture on the simulator screen along with the prediction results.
