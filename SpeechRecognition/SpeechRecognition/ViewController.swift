//// Copyright (c) 2020 Facebook, Inc. and its affiliates.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree.



import UIKit
import AVFoundation

extension String {
    func stringByAppendingPathComponent(path: String) -> String {
        let s = self as NSString
        return s.appendingPathComponent(path)
    }
}

class ViewController: UIViewController, AVAudioRecorderDelegate  {

    @IBOutlet weak var btnStart: UIButton!
    @IBOutlet weak var tvResult: UITextView!
    
    private var audioRecorder: AVAudioRecorder!
    private var _recorderFilePath: String!

    private lazy var module: InferenceModule = {
        if let filePath = Bundle.main.path(forResource:
            "wav2vec_traced_quantized", ofType: "pt"),
            let module = InferenceModule(fileAtPath: filePath) {
            return module
        } else {
            fatalError("Can't find the model file!")
        }
    }()
        

    
    @IBAction func startTapped(_ sender: Any) {
        AVAudioSession.sharedInstance().requestRecordPermission ({(granted: Bool)-> Void in
            if granted {
                self.btnStart.setTitle("Listening...", for: .normal)

            } else{
                self.tvResult.text = "Record premission needs to be granted, Record premission needs to be granted, Record premission needs to be granted"
            }
         })
        
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(AVAudioSession.Category.record)
            try audioSession.setActive(true)
        } catch {
            print("recording exception")
            return
        }

        let settings = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ] as [String : Any]
        
        do {
            _recorderFilePath = NSHomeDirectory().stringByAppendingPathComponent(path: "tmp").stringByAppendingPathComponent(path: "recorded_file.wav")
            print("recorderFilePath="+_recorderFilePath.description)
            audioRecorder = try AVAudioRecorder(url: NSURL.fileURL(withPath: _recorderFilePath), settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record(forDuration: 6)
        } catch let error {
            print("error:" + error.localizedDescription)
        }
    }

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        btnStart.setTitle("Recognizing...", for: .normal)
        
        if flag {

            let url = NSURL.fileURL(withPath: _recorderFilePath)
            let file = try! AVAudioFile(forReading: url)
            let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: file.fileFormat.sampleRate, channels: 1, interleaved: false)

            let buf = AVAudioPCMBuffer(pcmFormat: format!, frameCapacity: AVAudioFrameCount(file.length))
            try! file.read(into: buf!)

            var floatArray = Array(UnsafeBufferPointer(start: buf?.floatChannelData![0], count:Int(buf!.frameLength)))

            DispatchQueue.global().async {
                floatArray.withUnsafeMutableBytes {
                    let result = self.module.recognize(wavBuffer: $0.baseAddress!)
                    DispatchQueue.main.async {
                        self.tvResult.text = result
                        self.btnStart.setTitle("Start", for: .normal)
                    }
                }
            }
        }
        else {
            tvResult.text = "Recording error"
        }
    }


}

