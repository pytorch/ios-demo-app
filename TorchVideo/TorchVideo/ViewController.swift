//// Copyright (c) 2020 Facebook, Inc. and its affiliates.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree.


import UIKit
import AVKit
import AVFoundation

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var btnTest: UIButton!
    
    private let testVideos = ["video1", "video2", "video3"]
    private var videoIndex = 0
    
    private var inferencer = VideoClassifier()
    
    private var lblResult: UILabel!
    private var player : AVPlayer?
    private var playerController :AVPlayerViewController?
    
    private var timeObserverToken: Any?
    

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        player?.pause()
        if let pc = playerController {
            lblResult.removeFromSuperview()
            pc.view.removeFromSuperview()
            pc.removeFromParent()
            if let tmObserver = timeObserverToken {
                player!.removeTimeObserver(tmObserver as Any)
                timeObserverToken = nil
            }
        }
    }
    
    
    @IBAction func testTapped(_ sender: Any) {
        btnTest.setTitle(String(format: "Test %d/%d", videoIndex + 1, testVideos.count), for:.normal)

        guard let path = Bundle.main.path(forResource: testVideos[videoIndex], ofType:"mp4") else {
            return
        }
        playVideo(url: URL(fileURLWithPath: path), path: path)        
        videoIndex = (videoIndex + 1) % testVideos.count
    }
    
    @IBAction func selectTapped(_ sender: Any) {
        player?.pause()
        
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self;
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.mediaTypes = ["public.movie"]
        self.present(imagePickerController, animated: true, completion: nil)
    }
    
    @IBAction func liveTapped(_ sender: Any) {
        player?.pause()
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self;
            imagePickerController.sourceType = .camera
            self.present(imagePickerController, animated: true, completion: nil)
        }
    }
    
    
    private func playVideo(url: URL, path: String) {
        if let pc = playerController {
            lblResult.removeFromSuperview()
            pc.view.removeFromSuperview()
            pc.removeFromParent()
            if let tmObserver = timeObserverToken {
                player!.removeTimeObserver(tmObserver as Any)
                timeObserverToken = nil
            }
        }
        
        player = AVPlayer(url: url)
        playerController = AVPlayerViewController()
        playerController?.player = player
        
        playerController?.view.frame = CGRect(x: 0, y: 200, width: 400, height: 240)
        lblResult = UILabel()
        lblResult.frame = CGRect(x: 0, y: 200 - 46, width: 400, height: 46)
        lblResult.backgroundColor = UIColor.blue
        lblResult.textColor = UIColor.white
        lblResult.numberOfLines = 2
        lblResult.lineBreakMode = .byWordWrapping
        lblResult.textAlignment = .center
        self.view.addSubview((playerController?.view)!)
        self.view.addSubview(lblResult)
        self.addChild(playerController!)

        let timeScale = CMTimeScale(NSEC_PER_SEC)
        let time = CMTime(seconds: 1.0, preferredTimescale: timeScale)

        timeObserverToken = player!.addPeriodicTimeObserver(forInterval: time,
                                                          queue: .main) {
            [weak self] time in
                DispatchQueue.global().async {
                    let startTime = CACurrentMediaTime()
                    var pixelBuffer = [Float32]()
                    for n in 0...3 {
                        if let image = self!.frameFromVideo(path: path, at: time.seconds + Double(n) * 0.3) {
                            let resizedImage = image.resized(to: CGSize(width: CGFloat(PrePostProcessor.inputWidth), height: CGFloat(PrePostProcessor.inputHeight)))
                        
                            guard let frameBuffer = resizedImage.normalized() else { return }
                            pixelBuffer += frameBuffer
                        }
                    }

                    guard let top5Indexes = self!.inferencer.module.classify(frames: &pixelBuffer) else {
                        return
                    }
                    let inferenceTime = CACurrentMediaTime() - startTime
                                                
                    DispatchQueue.main.async {
                        let results = top5Indexes.map { self!.inferencer.classes[$0.intValue] }
                        self!.lblResult.text = "\(Int(time.seconds))s: " +    results.joined(separator: ", ") + " - \(Int(1000*inferenceTime))ms"
                    }
                }
            }

        player!.play()
    }

    func frameFromVideo(path: String, at time: Double) -> UIImage? {
        let asset = AVURLAsset(url: URL(fileURLWithPath: path))
        let assetIG = AVAssetImageGenerator(asset: asset)
        assetIG.appliesPreferredTrackTransform = true
        assetIG.apertureMode = AVAssetImageGenerator.ApertureMode.encodedPixels

        let cmTime = CMTime(value: CMTimeValue(time * 1000000), timescale: CMTimeScale(USEC_PER_SEC))

        let frameRef: CGImage
        do {
            frameRef = try assetIG.copyCGImage(at: cmTime, actualTime: nil)
        } catch let error {
            print("Error: \(error)")
            return nil
        }

        return UIImage(cgImage: frameRef)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let videoURL = info[UIImagePickerController.InfoKey.mediaURL] as! URL
        playVideo(url: videoURL as URL, path: videoURL.path)
        self.dismiss(animated: true, completion: nil)
    
    }
    
}

