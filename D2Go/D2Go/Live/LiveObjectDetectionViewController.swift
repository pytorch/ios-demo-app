// Copyright (c) 2020 Facebook, Inc. and its affiliates.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree.

import AVFoundation
import UIKit

class LiveObjectDetectionViewController: ViewController {
    @IBOutlet var cameraView: CameraPreviewView!
    @IBOutlet var benchmarkLabel: UILabel!
    @IBOutlet var indicator: UIActivityIndicatorView!

    private let delayMs: Double = 1000
    private var prevTimestampMs: Double = 0.0
    private var cameraController = CameraController()
    private var imageViewLive =  UIImageView()
    private var inferencer = ObjectDetector()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cameraController.configPreviewLayer(cameraView)
        imageViewLive.frame = CGRect(x: 0, y: 0, width: cameraView.frame.size.width, height: cameraView.frame.size.height)
        cameraView.addSubview(imageViewLive)
        
        cameraController.videoCaptureCompletionBlock = { [weak self] buffer, error in
            guard let strongSelf = self else { return }
            if error != nil {
                return
            }
            guard var pixelBuffer = buffer else { return }
            
            let currentTimestamp = CACurrentMediaTime()
            if (currentTimestamp - strongSelf.prevTimestampMs) * 1000 <= strongSelf.delayMs { return }
            strongSelf.prevTimestampMs = currentTimestamp
            let startTime = CACurrentMediaTime()
            guard let outputs = self?.inferencer.module.detect(image: &pixelBuffer) else {
                return
            }
            let inferenceTime = CACurrentMediaTime() - startTime
                
            DispatchQueue.main.async {
                let ivScaleX : Double =  Double(strongSelf.imageViewLive.frame.size.width / CGFloat(PrePostProcessor.inputWidth))
                let ivScaleY : Double = Double(strongSelf.imageViewLive.frame.size.height / CGFloat(PrePostProcessor.inputHeight))

                let startX = Double((strongSelf.imageViewLive.frame.size.width - CGFloat(ivScaleX) * CGFloat(PrePostProcessor.inputWidth))/2)
                let startY = Double((strongSelf.imageViewLive.frame.size.height -  CGFloat(ivScaleY) * CGFloat(PrePostProcessor.inputHeight))/2)
                
                let predictions = PrePostProcessor.outputsToPredictions(outputs: outputs, imgScaleX: 1.0, imgScaleY: 1.0, ivScaleX: ivScaleX, ivScaleY: ivScaleY, startX: startX, startY: startY)

                PrePostProcessor.cleanDetection(imageView: strongSelf.imageViewLive)
                strongSelf.indicator.isHidden = true
                strongSelf.benchmarkLabel.isHidden = false
                strongSelf.benchmarkLabel.text = String(format: "%.2fms", 1000*inferenceTime)
                
                PrePostProcessor.showDetection(imageView: strongSelf.imageViewLive, nmsPredictions: predictions, classes: strongSelf.inferencer.classes)
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        cameraController.startSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cameraController.stopSession()
    }

    @IBAction func backClicked(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}
