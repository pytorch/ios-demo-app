//// Copyright (c) 2020 Facebook, Inc. and its affiliates.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree.



import UIKit
import AVKit
import AVFoundation

class ViewController: UIViewController {
    @IBOutlet weak var btnTest: UIButton!
    @IBOutlet weak var ivFrame: UIImageView!
    
    private let testVideos = ["video1", "video2", "video3"]
    private var videoIndex = 0
    
    private var inferencer = VideoClassifier()
    
    private var player : AVPlayer?
    private var playerController :AVPlayerViewController?
    
    private var timeObserverToken: Any?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        playVideo()
    }
    
    
    @IBAction func testTapped(_ sender: Any) {
        videoIndex = (videoIndex + 1) % testVideos.count
        btnTest.setTitle(String(format: "Test %d/%d", videoIndex + 1, testVideos.count), for:.normal)
        playVideo()
    }
    
    @IBAction func selectTapped(_ sender: Any) {
    }
    
    @IBAction func liveTapped(_ sender: Any) {
    }
    
    
    private func playVideo() {
        guard let path = Bundle.main.path(forResource: testVideos[videoIndex], ofType:"mp4") else {
            return
        }
        
        if let pc = playerController {
            pc.view.removeFromSuperview()
            pc.removeFromParent()
        }
        
        player = AVPlayer(url: URL(fileURLWithPath: path))
        playerController = AVPlayerViewController()
        playerController?.player = player
        
        playerController?.view.frame = CGRect(x: 0, y: 200, width: 400, height: 240)
        self.view.addSubview((playerController?.view)!)
        self.addChild(playerController!)

        let timeScale = CMTimeScale(NSEC_PER_SEC)
        let time = CMTime(seconds: 0.5, preferredTimescale: timeScale)

        timeObserverToken = player!.addPeriodicTimeObserver(forInterval: time,
                                                          queue: .main) {
            [weak self] time in
                
                DispatchQueue.global().async {
                    if let image = self!.imageFromVideo(path: path, at: time.seconds) {
                        
                        let resizedImage = image.resized(to: CGSize(width: CGFloat(PrePostProcessor.inputWidth), height: CGFloat(PrePostProcessor.inputHeight)))

                        
                        DispatchQueue.main.async {
                            self!.ivFrame.image = resizedImage
                        }
                    
                        guard var pixelBuffer = resizedImage.normalized() else {
                            return
                        }
                        
                        pixelBuffer += pixelBuffer
                        pixelBuffer += pixelBuffer

                    guard let outputs = self!.inferencer.module.classify(frames: &pixelBuffer) else {
                        return
                    }
                        
                    print(outputs)

                }
            }

                
        }

        player!.play()
        
        
    }

    func imageFromVideo(path: String, at time: Double) -> UIImage? {
        let asset = AVURLAsset(url: URL(fileURLWithPath: path))
        let assetIG = AVAssetImageGenerator(asset: asset)
        assetIG.appliesPreferredTrackTransform = true
        assetIG.apertureMode = AVAssetImageGenerator.ApertureMode.encodedPixels

        let cmTime = CMTime(value: CMTimeValue(time*1000000), timescale: CMTimeScale(USEC_PER_SEC))

        let frameRef: CGImage
        do {
            frameRef = try assetIG.copyCGImage(at: cmTime, actualTime: nil)
        } catch let error {
            print("Error: \(error)")
            return nil
        }

        return UIImage(cgImage: frameRef)
    }
    

}

