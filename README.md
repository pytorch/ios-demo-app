## PyTorch iOS Examples

### Requirements

- XCode 11.0 or above
- iOS 12.0 or above

## Quick Start with a HelloWorld Example

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

### PyTorch demo app

For more complex use cases, we recommend to check out the PyTorch demo application. The demo app contains two showcases. A camera app that runs a quantized model to predict the images coming from device’s rear-facing camera in real time.  And a text-based app that uses a text classification model to predict the topic from the input string.

## Quickstart with the Image Segmentation iOS App

Open a Mac Terminal, run the commands below before selecting the iPhone 11 simulator on Xcode to run the app:

```
python deeplabv3.py
```

Note that the Python script above is used to generate the TorchScript-formatted model for mobile apps. If you don't have the PyTorch environment set up to run the script, you can download the model file to the `ios-demo-app` folder using the link [here](https://drive.google.com/file/d/17KeE6mKo67l14XxTl8a-NbtqwAvduVZG/view?usp=sharing).

```
cd ImageSegmentation
cp ../deeplabv3_scripted.pt ImageSegmentation
pod install
open ImageSegmentation.xcworkspace
```

## Quickstart with the Neural Machine Translation iOS App

Open a Mac Terminal, run the commands below:
```
cd Seq2SeqNMT
pod install
open Seq2SeqNMT.xcworkspace
```

Download the TorchScript encoder and decoder model files [here](https://drive.google.com/file/d/1TxB5oStgShrNvlSVlVaGylNUi4PTtufQ/view?usp=sharing), then copy the two files to the Seq2SeqNMT/Seq2SeqNMT folder, select the iPhone 11 simulator or an iOS device on Xcode to run the app.



## LICENSE

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
