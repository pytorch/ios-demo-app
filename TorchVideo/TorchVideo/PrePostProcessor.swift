//// Copyright (c) 2020 Facebook, Inc. and its affiliates.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree.

import UIKit

struct Prediction {
  let classIndex: Int
  let score: Float
  let rect: CGRect
}

class PrePostProcessor : NSObject {
    // target video input size
    static let inputWidth = 160
    static let inputHeight = 160
    
    static let countOfFramesPerInference = 4
    static let topCount = 5
}

