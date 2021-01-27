// Copyright (c) 2020 Facebook, Inc. and its affiliates.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree.


import Foundation

class HandwrittenDigitRecognizer {
    private let MNIST_IMAGE_SIZE = 28
    private let MNIST_STD = 0.1307
    private let MNIST_MEAN = 0.3081

    private var module: InferenceModule = {
        if let filePath = Bundle.main.path(forResource: "vit4mnist", ofType: "pth"),
            let module = InferenceModule(fileAtPath: filePath) {
            return module
        } else {
            fatalError("Failed to load model file vit4mnist.pth")
        }
    }()
        
    
    func recognize(allPoints: [[CGPoint]], width: CGFloat, height: CGFloat) -> String? {
        if (allPoints.count == 0) {
            return nil
        }
        let BLANK = -MNIST_STD / MNIST_MEAN
        let NON_BLANK = (1.0 - MNIST_STD) / MNIST_MEAN

        var inputs = Array(repeating: BLANK, count: MNIST_IMAGE_SIZE * MNIST_IMAGE_SIZE)
        
        // loop through each stroke
        for consecutivePoints in allPoints {
            // loop through each point in the stroke
            for point in consecutivePoints {
                if point.x > width || point.y > height ||
                    point.x < 0 || point.y < 0 {
                    continue;
                }
                let x = MNIST_IMAGE_SIZE * Int(point.x) / Int(width)
                let y = MNIST_IMAGE_SIZE * Int(point.y) / Int(height)
                let loc = y * MNIST_IMAGE_SIZE + x
                inputs[loc] = NON_BLANK
            }
        }
        
        return module.recognize(points: inputs)
    }
}
