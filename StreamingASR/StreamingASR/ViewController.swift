//// Copyright (c) 2020 Facebook, Inc. and its affiliates.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree.



import UIKit
import AVFoundation
import Foundation


class ViewController: UIViewController {
    @IBOutlet weak var btnStart: UIButton!
    @IBOutlet weak var tvResult: UITextView!
    
    let audioEngine = AVAudioEngine()
    let serialQueue = DispatchQueue(label: "sasr.serial.queue")
    
    private let AUDIO_LEN_IN_SECOND = 6
    private let SAMPLE_RATE = 16000
    
    private let CHUNK_TO_READ = 5
    private let CHUNK_SIZE = 640
    private let INPUT_SIZE = 3200
    
    
    private let module: InferenceModule = {
        if let filePath = Bundle.main.path(forResource:
            "streaming_asrv2", ofType: "ptl"),
            let module = InferenceModule(fileAtPath: filePath) {
            return module
        } else {
            fatalError("Can't find the model file!")
        }
    }()
    

    @IBAction func startTapped(_ sender: Any) {
        if (self.btnStart.title(for: .normal)! == "Start") {
            self.btnStart.setTitle("Listening... Stop", for: .normal)
            
            do {
              try self.startRecording()
            } catch let error {
              print("There was a problem starting recording: \(error.localizedDescription)")
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
        let inputNode = audioEngine.inputNode
        let inputNodeOutputFormat = inputNode.outputFormat(forBus: 0)
        let targetFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: Double(SAMPLE_RATE), channels: 1, interleaved: false)
        let formatConverter =  AVAudioConverter(from:inputNodeOutputFormat, to: targetFormat!)
        var pcmBufferToBeProcessed = [Float32]()
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputNodeOutputFormat) { [unowned self] (buffer, _) in
                let pcmBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat!, frameCapacity: AVAudioFrameCount(targetFormat!.sampleRate) / 10)
                var error: NSError? = nil
            
                let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
                    outStatus.pointee = AVAudioConverterInputStatus.haveData
                    return buffer
                }
                formatConverter!.convert(to: pcmBuffer!, error: &error, withInputFrom: inputBlock)

                let floatArray = Array(UnsafeBufferPointer(start: pcmBuffer!.floatChannelData![0], count:Int(pcmBuffer!.frameLength)))
                pcmBufferToBeProcessed += floatArray
            
                if pcmBufferToBeProcessed.count >= CHUNK_TO_READ * CHUNK_SIZE {
                    let samples = Array(pcmBufferToBeProcessed[0..<CHUNK_TO_READ * CHUNK_SIZE]) .map { Double($0)/1.0 }
                    pcmBufferToBeProcessed = Array(pcmBufferToBeProcessed[(CHUNK_TO_READ - 1) * CHUNK_SIZE..<pcmBufferToBeProcessed.count])
                    
                    serialQueue.async {
                        var modelInput = [Float32]()
                        
                        for i in 0..<INPUT_SIZE {
                            modelInput.append(Float32(samples[i]))
                        }
                                            
                        var result = self.module.recognize(&modelInput)
                        if result!.count > 0 {
                            result = result!.replacingOccurrences(of: "▁", with: "")
                            DispatchQueue.main.async {
                                self.tvResult.text = self.tvResult.text + " " + result!
                            }
                        }
                    }
                }
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    
    fileprivate func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
    }
}
