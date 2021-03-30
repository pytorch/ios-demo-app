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
    var audioRecorder: AVAudioRecorder!
    let _lbl = UILabel()
    let _btn = UIButton(type: .system)
    var _recorderFilePath: String!

    
    private lazy var module: InferenceModule = {
        if let filePath = Bundle.main.path(forResource:
            "wav2vec_traced_quantized", ofType: "pt"),
            let module = InferenceModule(fileAtPath: filePath) {
            return module
        } else {
            fatalError("Can't find the model file!")
        }
    }()
        
        
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        _btn.translatesAutoresizingMaskIntoConstraints = false
        _btn.titleLabel?.font = UIFont.systemFont(ofSize:32)
        _btn.setTitle("Start", for: .normal)
        self.view.addSubview(_btn)
        
        let horizontal = NSLayoutConstraint(item: _btn, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1, constant: 0)
        
        let vertical = NSLayoutConstraint(item: _btn, attribute: .centerY, relatedBy: .equal, toItem: self.view, attribute: .centerY, multiplier: 1, constant: 0)

        self.view.addConstraint(horizontal)
        self.view.addConstraint(vertical)
        
        _btn.addTarget(self, action:#selector(btnTapped), for: .touchUpInside)
        
        _lbl.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(_lbl)
        
        let horizontal2 = NSLayoutConstraint(item: _lbl, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1, constant: 0)
        
        let vertical2 = NSLayoutConstraint(item: _lbl, attribute: .centerY, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: 150)
        
        self.view.addConstraint(horizontal2)
        self.view.addConstraint(vertical2)

        
    }

    @objc func btnTapped() {
        _lbl.text = "..."
        _btn.setTitle("Listening...", for: .normal)
        
        AVAudioSession.sharedInstance().requestRecordPermission () {
            [unowned self] allowed in
            if allowed {
                print("mic allowed")
            } else {
                print("denied by user")
                return
            }
        }
        
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
        _btn.setTitle("Recognizing...", for: .normal)
        
        if flag {

            let url = NSURL.fileURL(withPath: _recorderFilePath)
            let file = try! AVAudioFile(forReading: url)
            let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: file.fileFormat.sampleRate, channels: 1, interleaved: false)

            let buf = AVAudioPCMBuffer(pcmFormat: format!, frameCapacity: AVAudioFrameCount(file.length))
            try! file.read(into: buf!)

            var floatArray = Array(UnsafeBufferPointer(start: buf?.floatChannelData![0], count:Int(buf!.frameLength)))

//            let floatArray = UnsafeMutableRawPointer(start: buf?.floatChannelData![0], count:Int(buf!.frameLength))
//
            
            DispatchQueue.global().async {
                floatArray.withUnsafeMutableBytes {
                    let result = self.module.recognize(wavBuffer: $0.baseAddress!)
                    DispatchQueue.main.async {
                        //_lbl.text = result
                    }
                }
            }
        }
        else {
            _lbl.text = "Recording error"
        }
        _btn.setTitle("Start", for: .normal)
    }


}

