// Copyright (c) 2020 Facebook, Inc. and its affiliates.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree.


import UIKit

class ViewController: UIViewController {
    var inferencer = HandwrittenDigitRecognizer()
    
    @IBOutlet weak var lblResult: UILabel!
    @IBOutlet weak var btnRecognize: UIButton!
    @IBOutlet weak var ivHandwritten: UIImageView!
    
    private var allPoints = [[CGPoint]]()
    private var consecutivePoints = [CGPoint]()
    private let imageHelper = ImageHelper()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        lblResult.text = ""
    }

    @IBAction func recognizeTapped(_ sender: Any) {
        btnRecognize.isEnabled = false
        btnRecognize.setTitle("Running...", for: .normal)
        let width = self.ivHandwritten.frame.width
        let height = self.ivHandwritten.frame.height
        DispatchQueue.global().async {
            if let result = self.inferencer.recognize(allPoints: self.allPoints, width:width, height:height) {
                DispatchQueue.main.async {
                    self.btnRecognize.isEnabled = true
                    self.btnRecognize.setTitle("Recognize", for: .normal)
                    self.lblResult.text = result
                }
            }
        }
    }
    
    @IBAction func clearTapped(_ sender: Any) {
        consecutivePoints.removeAll()
        allPoints.removeAll()
        ivHandwritten.image = nil
        lblResult.text = ""
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let point = touch.location(in: ivHandwritten)
            consecutivePoints.removeAll()
            consecutivePoints.append(point)
            ivHandwritten.image = imageHelper.createDrawingImage(in: ivHandwritten.frame, allPoints: allPoints, consecutivePoints: consecutivePoints)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let point = touch.location(in: ivHandwritten)
            consecutivePoints.append(point)
            ivHandwritten.image = imageHelper.createDrawingImage(in: ivHandwritten.frame, allPoints: allPoints, consecutivePoints: consecutivePoints)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let point = touch.location(in: ivHandwritten)
            consecutivePoints.append(point)
            allPoints.append(consecutivePoints)
            ivHandwritten.image = imageHelper.createDrawingImage(in: ivHandwritten.frame, allPoints: allPoints, consecutivePoints: consecutivePoints)
        }
    }
}

