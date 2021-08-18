### Requirements

- XCode 11.0 or above
- iOS 12.0 or above

## The HelloWorldMetal Example

HelloWorldMetal is a simple image classification application that demonstrates how to use PyTorch C++ libraries with Metal support. The code is written in Swift and uses Objective-C as a bridge.

We’ll be using the mobilenetv2 model as an example. Since the mobile GPU features are currently in the prototype stage, you’ll need to build a custom pytorch binary from source. For the time being, only a limited number of operators are supported, and certain client side APIs are subject to change in the future versions.

### Model Preparation

Since GPUs consume weights in a different order, the first step we need to do is to convert our TorchScript model to a GPU compatible model. This step is also known as “prepacking”. To do that, we’ll build a custom pytorch binary from source that includes the Metal backend. Go ahead checkout the pytorch source code from github and run the command below

```shell
cd PYTORCH_ROOT
USE_PYTORCH_METAL=ON python setup.py install --cmake
```

The command above will build a custom pytorch binary from master. The `install` argument simply tells `setup.py` to override the existing PyTorch on your desktop. Once the build finished, open another terminal to check the PyTorch version to see if the installation was successful. As the time of writing of this recipe, the version is `1.8.0a0+41237a4`. You might be seeing different numbers depending on when you check out the code from master, but it should be greater than 1.7.0.

```python
import torch
torch.__version__ #1.8.0a0+41237a4
```

The next step is going to be converting the mobilenetv2 torchscript model to a Metal compatible model. Navigate to the HelloWorldMetal folder and run `trace_model.py` to generate our model.

```shell
python trace_model.py
```

If everything works well, `model.pt` should be generated and saved in the `HelloWorldMetal/HelloWorldMetal/model`.

### Install LibTorch-Lite-Nightly via Cocoapods

The PyTorch C++ library with Metal support is available in [Cocoapods](https://cocoapods.org/), to integrate it to our project, we can run

```ruby
pod install
```
Now open the `HelloWorldMetal.xcworkspace` in XCode, select an iOS simulator and launch it (cmd + R). If everything works well, we should see a wolf picture on the simulator screen along with the prediction results.

<img src="screenshot.png?raw=true" width="50%">
