// Copyright (c) 2020 Facebook, Inc. and its affiliates.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree.

import AVFoundation
import UIKit

class LiveVideoClassificationViewController: ViewController {
  @IBOutlet var cameraView: CameraPreviewView!
  @IBOutlet var lblResult: UILabel!
  @IBOutlet var indicator: UIActivityIndicatorView!

  private let delayMs: Double = 1000
  private var prevTimestampMs: Double = 0.0
  private var cameraController = CameraController()
  private var imageViewLive =  UIImageView()
  private var inferencer = VideoClassifier()

  override func viewDidLoad() {
    super.viewDidLoad()
    self.navigationController?.setNavigationBarHidden(false, animated: true)

    cameraController.configPreviewLayer(cameraView)
    imageViewLive.frame = CGRect(x: 0, y: 0, width: cameraView.frame.size.width, height: cameraView.frame.size.height)
    cameraView.addSubview(imageViewLive)

    cameraController.videoCaptureCompletionBlock = { [weak self] buffer, error in
      let currentTimestamp = CACurrentMediaTime()
      guard let strongSelf = self,
            var pixelBuffer = buffer,
            error == nil,
            (currentTimestamp - strongSelf.prevTimestampMs) * 1000 > strongSelf.delayMs
      else {
        return
      }

      strongSelf.prevTimestampMs = currentTimestamp

      // simulate 4 frames of image as requested by model input
      pixelBuffer += pixelBuffer
      pixelBuffer += pixelBuffer

      let startTime = CACurrentMediaTime()
      guard let floatPointer = strongSelf.inferencer.module.classify(frames: &pixelBuffer) else {
        return
      }
      let inferenceTime = CACurrentMediaTime() - startTime

      let classes = strongSelf.inferencer.classes
      DispatchQueue.main.async {
        let bufferPointer = UnsafeBufferPointer(start: floatPointer, count: classes.count)
        let zippedResults = zip(bufferPointer, classes.indices)
        let sortedResults = zippedResults.sorted { $0.0 > $1.0 }.prefix(classes.count).prefix(5)
        let results = sortedResults.map { classes[$0.1] }
        strongSelf.lblResult.text = results.joined(separator: ", ") + " - \(Int(1000*inferenceTime))ms"
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
