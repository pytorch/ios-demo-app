## Quick Start
### To Test Run the Image Segmentation iOS App

Open a Mac Terminal, run the commands below before selecting the iPhone 11 simulator or an iOS device on Xcode to run the app:

```
git clone https://github.com/pytorch/ios-demo-app
cd ios-demo-app/ImageSegmentation
python deeplabv3.py
```

Note that the Python script above is used to generate the TorchScript-formatted model for mobile apps. If you don't have the PyTorch environment set up to run the script, you can download the model file to the `ios-demo-app/ImageSegmentation` folder using the link [here](https://drive.google.com/file/d/17KeE6mKo67l14XxTl8a-NbtqwAvduVZG/view?usp=sharing).

```
cp deeplabv3_scripted.pt ImageSegmentation
pod install
open ImageSegmentation.xcworkspace/
```
