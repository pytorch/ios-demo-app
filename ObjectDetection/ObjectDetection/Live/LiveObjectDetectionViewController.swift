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
    private var cameraController = CameraController()
    private var imageViewLive =  UIImageView()

    private let delayMs: Double = 1000
    private var prevTimestampMs: Double = 0.0
    private let width: CGFloat = 640
    private let height: CGFloat = 640
    
    private var classes: [String] = {
        if let filePath = Bundle.main.path(forResource: "classes", ofType: "txt"),
            let classes = try? String(contentsOfFile: filePath) {
            return classes.components(separatedBy: .newlines)
        } else {
            fatalError("classes file was not found.")
        }
    }()
    
    private lazy var module: InferenceModule = {
        if let filePath = Bundle.main.path(forResource: "yolov5s.torchscript", ofType: "pt"),
            let module = InferenceModule(fileAtPath: filePath) {
            return module
        } else {
            fatalError("Can't find the model file!")
        }
    }()

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
            guard let outputs = self?.module.detect(image: UnsafeMutableRawPointer(&pixelBuffer)) else {
                return
            }
            let inferenceTime = CACurrentMediaTime() - startTime
                
            DispatchQueue.main.async {
                let ivScaleX : Double =  Double(strongSelf.imageViewLive.frame.size.width / strongSelf.width)
                let ivScaleY : Double = Double(strongSelf.imageViewLive.frame.size.height / strongSelf.height)

                let startX = Double((strongSelf.imageViewLive.frame.size.width - CGFloat(ivScaleX) * strongSelf.width)/2)
                let startY = Double((strongSelf.imageViewLive.frame.size.height -  CGFloat(ivScaleY) * strongSelf.height)/2)
                
                let nmsPredictions = PostProcessor.outputsToNMSPredictions(outputs: outputs, imgScaleX: 1.0, imgScaleY: 1.0, ivScaleX: ivScaleX, ivScaleY: ivScaleY, startX: startX, startY: startY)

                PostProcessor.cleanDrawing(imageView: strongSelf.imageViewLive)
                strongSelf.indicator.isHidden = true
                strongSelf.benchmarkLabel.isHidden = false
                strongSelf.benchmarkLabel.text = String(format: "%.2fms, %.2f", CACurrentMediaTime() - startTime, inferenceTime)
                
                for pred in nmsPredictions {
                    let bbox = UIView(frame: pred.rect)
                    bbox.backgroundColor = UIColor.clear
                    bbox.layer.borderColor = UIColor.yellow.cgColor
                    bbox.layer.borderWidth = 3
                    strongSelf.imageViewLive.addSubview(bbox)
                    
                    let textLayer = CATextLayer()
                    textLayer.string = String(format: " %@ %.2f", strongSelf.classes[pred.classIndex], pred.score)
                    textLayer.foregroundColor = UIColor.red.cgColor
                    textLayer.fontSize = 18
                    textLayer.frame = CGRect(x: pred.rect.origin.x, y: pred.rect.origin.y, width:100, height:25)
                    strongSelf.imageViewLive.layer.addSublayer(textLayer)
                }
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

    @IBAction func onBackClicked(_: Any) {
        navigationController?.popViewController(animated: true)
    }
}
