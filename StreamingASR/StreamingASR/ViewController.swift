//// Copyright (c) 2020 Facebook, Inc. and its affiliates.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree.



import UIKit
import AVFoundation
import RosaKit


class ViewController: UIViewController {
    @IBOutlet weak var btnStart: UIButton!
    @IBOutlet weak var tvResult: UITextView!
    
    private var mListening: Bool!
    
    private let AUDIO_LEN_IN_SECOND = 6
    private let SAMPLE_RATE = 16000
    
    private let CHUNK_TO_READ = 5
    private let CHUNK_SIZE = 640
    private let SPECTROGRAM_X = 21
    private let SPECTROGRAM_Y = 80

    let audioEngine = AVAudioEngine()
    

    private let module: InferenceModule = {
        if let filePath = Bundle.main.path(forResource:
            "streaming_asr", ofType: "ptl"),
            let module = InferenceModule(fileAtPath: filePath) {
            return module
        } else {
            fatalError("Can't find the model file!")
        }
    }()
    

    @IBAction func startTapped(_ sender: Any) {
        if (self.btnStart.title(for: .normal)! == "Start") {
            self.btnStart.setTitle("Listening... Stop", for: .normal)
            self.mListening = true
            
            do {
              try self.startRecording()
            } catch let error {
              print("There was a problem starting recording: \(error.localizedDescription)")
            }
        }
        else {
            self.btnStart.setTitle("Start", for: .normal)
            self.mListening = false            
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
            let pcmBuffer = AVAudioPCMBuffer(pcmFormat: recordingFormat!, frameCapacity: AVAudioFrameCount(recordingFormat!.sampleRate))
            var error: NSError? = nil
            
            let inputBlock: AVAudioConverterInputBlock = {inNumPackets, outStatus in
              outStatus.pointee = AVAudioConverterInputStatus.haveData
              return buffer
            }
        
            formatConverter!.convert(to: pcmBuffer!, error: &error, withInputFrom: inputBlock)
            
            var floatArray = Array(UnsafeBufferPointer(start: pcmBuffer!.floatChannelData![0], count:Int(pcmBuffer!.frameLength)))
            let rawAudioData = floatArray
            let chunkSize = 16000
            let samples = Array(rawAudioData[0..<chunkSize]).map { Double($0)/32768.0 }

            let melSpectrogram = samples.melspectrogram(nFFT: 400, hopLength: 160, sampleRate: Int(SAMPLE_RATE), melsCount: 80)
            // values are the same as in Android! except the size is 80x21 on iOS and 21x80 on Android
            
            DispatchQueue.global().async {
                floatArray.withUnsafeMutableBytes {
                    let result = self.module.recognize($0.baseAddress!, chunkToRead: Int32(CHUNK_TO_READ), chunkSize: Int32(CHUNK_SIZE))
                    print(result)

                }
            }

        /*
        DispatchQueue.global().async {

            var chunkToRead = self.CHUNK_TO_READ
            var recordingOffset = 0
            
            //short[] recordingBuffer = new short[CHUNK_TO_READ*CHUNK_SIZE];
            //double[] floatInputBuffer = new double[CHUNK_TO_READ * CHUNK_SIZE];

            while self.mListening {

                var shortsRead = 0
                var audioBuffer = Array(repeating: 0.0, count: 960)

                while shortsRead < chunkToRead * self.CHUNK_SIZE {
                    
                    // for every segment of 5 chunks of data, we perform transcription
                    // each successive segment’s first chunk is exactly the preceding segment’s last chunk
                    let numberOfShort = 1000 // record.read(audioBuffer, 0, audioBuffer.length);
                    shortsRead += numberOfShort
                    if shortsRead > chunkToRead * self.CHUNK_SIZE {
                        //System.arraycopy(audioBuffer, 0, recordingBuffer, recordingOffset, (int) (numberOfShort - (shortsRead - chunkToRead*640)));
                    }
                    else {
                        //System.arraycopy(audioBuffer, 0, recordingBuffer, recordingOffset, numberOfShort);
                    }

                    recordingOffset += numberOfShort
                }

                for i in 0...self.CHUNK_TO_READ * self.CHUNK_SIZE - 1{
                    //floatInputBuffer[i] = recordingBuffer[i] / (float)Short.MAX_VALUE;
                }

                //final String result = recognize(floatInputBuffer);
                //if result.length() > 0 {
                    //all_result = String.format("%s %s", all_result, result)
                //}
                let all_result = "aa"

                chunkToRead = self.CHUNK_TO_READ - 1
                recordingOffset = self.CHUNK_SIZE;
                //System.arraycopy(recordingBuffer, chunkToRead * CHUNK_SIZE, recordingBuffer, 0, CHUNK_SIZE);

                 floatArray.withUnsafeMutableBytes {
                     let result = self.module.recognize($0.baseAddress!, bufLength: Int32(self.AUDIO_LEN_IN_SECOND * self.SAMPLE_RATE))
                     
                     DispatchQueue.main.async {
                         self.tvResult.text = result
                         self.btnStart.setTitle("Start", for: .normal)
                     }
                }
            }
            

        }*/
                
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    fileprivate func stopRecording() {
        audioEngine.stop()
    }
}
