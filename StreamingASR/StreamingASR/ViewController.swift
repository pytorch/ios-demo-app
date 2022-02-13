//// Copyright (c) 2020 Facebook, Inc. and its affiliates.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree.



import UIKit
import AVFoundation
import Speech


extension String {
    func stringByAppendingPathComponent(path: String) -> String {
        let s = self as NSString
        return s.appendingPathComponent(path)
    }
}


class ViewController: UIViewController, AVAudioRecorderDelegate {
    @IBOutlet weak var btnStart: UIButton!
    @IBOutlet weak var tvResult: UITextView!
    
    private var audioRecorder: AVAudioRecorder!
    private var _recorderFilePath: String!
    private var mListening: Bool!
    
    private let AUDIO_LEN_IN_SECOND = 6
    private let SAMPLE_RATE = 16000
    
    private let CHUNK_TO_READ = 5
    private let CHUNK_SIZE = 640
    private let SPECTROGRAM_X = 21
    private let SPECTROGRAM_Y = 80

    let audioEngine = AVAudioEngine()
    let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    let speechRecognizer = SFSpeechRecognizer()
    


    private let module: InferenceModule = {
        if let filePath = Bundle.main.path(forResource:
            "streaming_asr", ofType: "ptl"),
            let module = InferenceModule(fileAtPath: filePath) {
            return module
        } else {
            fatalError("Can't find the model file!")
        }
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func startTapped(_ sender: Any) {
        if (self.btnStart.title(for: .normal)! == "Start") {
            self.btnStart.setTitle("Listening... Stop", for: .normal)
            self.mListening = true
        
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
            
//            if error != nil {
//              print(error!.localizedDescription)
//            }
//            else if let channelData = pcmBuffer!.int16ChannelData {
//
//              let channelDataPointer = channelData.pointee
//              let channelData = stride(from: 0,
//                                                 to: Int(pcmBuffer!.frameLength),
//                                                 by: buffer.stride).map{ channelDataPointer[$0] }
//                //Return channelDataValueArray
//
//
//          }
        
        var floatArray = Array(UnsafeBufferPointer(start: pcmBuffer!.floatChannelData![0], count:Int(pcmBuffer!.frameLength)))
        
//        var floatArray = Array(UnsafeBufferPointer(start: buffer.floatChannelData![0], count:Int(buffer.frameLength)))
        print("before recognize")
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
        
        //self.recognitionRequest.append(buffer)
        
        // this runs too but the recognition result is incorrect
        //self.recognitionRequest.append(pcmBuffer!)
        
//        (lldb) po buffer
//        <AVAudioPCMBuffer@0x283799940: 17640/17640 bytes>
//
//        (lldb) po pcmBuffer
//        ▿ Optional<AVAudioPCMBuffer>
//          - some : <AVAudioPCMBuffer@0x283799700: 64000/64000 bytes>
//
//        (lldb) po buffer.frameLength
//        4410
//
//        (lldb) po pcmBuffer!.frameLength
//        16000
        
    }

    audioEngine.prepare()
    try audioEngine.start()
      
//    recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) {
//      [unowned self]
//      (result, _) in
//      if let transcription = result?.bestTranscription {
//          //print(transcription)
//          print(transcription.formattedString)
//          tvResult.text = transcription.formattedString
//      }
//    }
  }

  fileprivate func stopRecording() {
    audioEngine.stop()
    recognitionRequest.endAudio()
    recognitionTask?.cancel()
  }
}
