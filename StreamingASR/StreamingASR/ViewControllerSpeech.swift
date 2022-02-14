//// Copyright (c) 2020 Facebook, Inc. and its affiliates.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree.



import UIKit
import AVFoundation
import Speech


class ViewController: UIViewController {
    @IBOutlet weak var btnStart: UIButton!
    @IBOutlet weak var tvResult: UITextView!
    
    private let SAMPLE_RATE = 16000
    
    let audioEngine = AVAudioEngine()
    let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    let speechRecognizer = SFSpeechRecognizer()
    

    @IBAction func startTapped(_ sender: Any) {
        if (self.btnStart.title(for: .normal)! == "Start") {
            self.btnStart.setTitle("Listening... Stop", for: .normal)
            
            SFSpeechRecognizer.requestAuthorization {
                [unowned self] (authStatus) in
                    switch authStatus {
                    case .authorized:
                        do {
                            try self.startRecording()
                        } catch let error {
                            print("There was a problem starting recording: \(error.localizedDescription)")
                        }
                    case .denied:
                        print("Speech recognition authorization denied")
                    case .restricted:
                        print("Not available on this device")
                    case .notDetermined:
                        print("Not determined")
                    }
            }
        }
        else {
            self.btnStart.setTitle("Start", for: .normal)
            self.stopRecording()
        }
    }
}

extension ViewController {
    fileprivate func startRecording() throws {
        let node = audioEngine.inputNode
        let inputFormat = node.outputFormat(forBus: 0)
          
        let recordingFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: Double(SAMPLE_RATE), channels: 1, interleaved: false)
        let formatConverter =  AVAudioConverter(from:inputFormat, to: recordingFormat!)

        node.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [unowned self]
                          (buffer, _) in
            self.recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
      
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) {
            [unowned self] (result, _) in
                if let transcription = result?.bestTranscription {
                    print(transcription.formattedString)
                    tvResult.text = transcription.formattedString
                }
        }
    }

    fileprivate func stopRecording() {
        audioEngine.stop()
        recognitionRequest.endAudio()
        recognitionTask?.cancel()
  }
}
