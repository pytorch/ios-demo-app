# Streaming Speech Recognition on iOS with Emformer-RNNT-based Model

## Introduction

In the Speech Recognition iOS [demo app](https://github.com/pytorch/ios-demo-app/tree/master/SpeechRecognition), we showed how to use the [wav2vec 2.0](https://github.com/pytorch/fairseq/tree/master/examples/wav2vec) model on an iOS demo app to perform non-continuous speech recognition. Here we're going one step further, using a torchaudio [Emformer-RNNT-based ASR](https://pytorch.org/audio/main/prototype.pipelines.html#torchaudio.prototype.pipelines.EMFORMER_RNNT_BASE_LIBRISPEECH) model in iOS to perform streaming speech recognition.

This demo uses iOS [AVAudioEngine](https://developer.apple.com/documentation/avfaudio/avaudioengine) instead of [AVAudioRecorder](https://github.com/pytorch/ios-demo-app/blob/master/SpeechRecognition/SpeechRecognition/ViewController.swift#L24) to perform live audio processing for the streaming speech recognition model. AVAudioRecorder is simple to use, but you can't process the audio before it is written to a target file. AVAudioEngine is a lot more powerful and supports real time audio analysis.


## Prerequisites

* PyTorch 1.12 and torchaudio 0.12 (Optional)
* Python 3.8 or above (Optional)
* iOS Cocoapods LibTorch-Lite 1.12.0
* Xcode 13 or later

## Quick Start

### 1. Get the Repo

Simply run the commands below:

```
git clone https://github.com/pytorch/ios-demo-app
cd ios-demo-app/StreamingASR
```

If you don't have PyTorch 1.12 and torchaudio 0.12 installed or want to have a quick try of the demo app, you can download the optimized scripted model file [streaming_asrv2.ptl](https://drive.google.com/file/d/1XRCAFpMqOSz5e7VP0mhiACMGCCcYfpk-/view?usp=sharing), then drag and drop it to the project, and continue to Step 3.


### 2. Test and Prepare the Model

To install PyTorch 1.12, torchaudio 0.12, and other required packages (numpy, pyaudio, and fairseq), do something like this:

```
conda create -n pt1.12 python=3.8.5
conda activate pt1.12
pip install torch torchaudio numpy pyaudio fairseq
```

First, create the model file `scripted_wrapper_tuple.pt` by running `python generate_ts.py`.

Then, to test the model, run `python run_sasr.py`. After you see:
```
Initializing model...
Initialization complete.
```
say something like "good afternoon happy new year", and you'll likely see the streaming recognition results `good afternoon happy new year` while you speak. Hit Ctrl-C to end.

Finally, to optimize and convert the model to the format that can run on Android, run the following commands:
```
python save_model_for_mobile.py
mv streaming_asrv2.ptl StreamingASR
```

### 3. Use LibTorch-Lite

Run the command `pod install` (if you're upgrading from PyTorch 1.11, you may need to run `pod repo update` first), and you will see `Installing LibTorch-Lite (1.12.0)`.

In the first version of the demo, the [RosaKit](https://github.com/dhrebeniuk/RosaKit) library is used to perform the audio [MelSpectrogram](https://pytorch.org/audio/stable/transforms.html#melspectrogram install) transformation. Since the updated model has the MelSpectrogram transformation built in, made possible since torchaudio version 0.11, we only need to feed the current mode with the raw audio input.

Now run `open StreamingASR.xcworkspace` to open the project in Xcode.

### 4. Build and run with Xcode

After the app runs, tap the Start button and start saying something. Unlike the wav2vec2 Speech Recognition demo app, you can perform streaming speech recognition without having to wait for the input audio to be recorded. Some example results are as follows:

![](screenshot1.png)
![](screenshot2.png)
![](screenshot3.png)

A quick note on how the model works to help you better understand the iOS code - for every segment of 5 chunks of data, we perform transcription, which does the following:

1. Apply data transformation function to convert the segment of audio data to a tensor of features.

2. Feed tensor of features and output of previous decoder invocation (token sequence and model state) to decoder, which iteratively runs the streaming ASR model to generate an output that comprises a token sequence (the recognition result) and model state.

3. Store token sequence and model state for use in the next decoder invocation on next segment of 5 chunks of data - first chunk is exactly the preceding segment’s last chunk.
