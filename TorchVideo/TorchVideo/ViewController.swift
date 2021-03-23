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
    
    private var player : AVPlayer?
    private var playerController :AVPlayerViewController?
    
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

        player!.play()
        
        ivFrame.image = imageFromVideo(path: path, at: 100)
        
    }

    func imageFromVideo(path: String, at time: TimeInterval) -> UIImage? {
        let asset = AVURLAsset(url: URL(fileURLWithPath: path))
        let assetIG = AVAssetImageGenerator(asset: asset)
        assetIG.appliesPreferredTrackTransform = true
        assetIG.apertureMode = AVAssetImageGenerator.ApertureMode.encodedPixels

        let cmTime = CMTime(seconds: time, preferredTimescale: 60)
        let thumbnailImageRef: CGImage
        do {
            thumbnailImageRef = try assetIG.copyCGImage(at: cmTime, actualTime: nil)
        } catch let error {
            print("Error: \(error)")
            return nil
        }

        return UIImage(cgImage: thumbnailImageRef)
    }
    

}

