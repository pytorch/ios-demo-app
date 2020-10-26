## Quick Start
### To Test Run the Image Segmentation iOS App

1. Open a Mac Terminal, run the following commands:

```
git clone https://github.com/pytorch/ios-demo-app
cd ios-demo-app/ImageSegmentation
python deeplabv3.py
```

The Python script `deeplabv3.py` is used to generate the TorchScript-formatted model for mobile apps. If you don't have the PyTorch environment set up to run the script, you can download the model file to the `ios-demo-app/ImageSegmentation` folder using the link [here](https://drive.google.com/file/d/17KeE6mKo67l14XxTl8a-NbtqwAvduVZG/view?usp=sharing).

2. Run the commands below:

```
cp deeplabv3_scripted.pt ImageSegmentation
pod install
open ImageSegmentation.xcworkspace/
```

3. Select the iPhone 11 simulator or an iOS device on Xcode to run the app.
