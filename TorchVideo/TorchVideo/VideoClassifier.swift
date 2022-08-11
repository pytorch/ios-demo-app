// Copyright (c) 2020 Facebook, Inc. and its affiliates.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree.

import UIKit

class VideoClassifier {
  lazy var module: InferenceModule = {
    guard let filePath = Bundle.main.path(forResource: "video_classification", ofType: "ptl"),
          let module = InferenceModule(fileAtPath: filePath)
    else {
      fatalError("Failed to load model!")
    }
    return module
  }()

  lazy var classes: [Substring] = {
    guard let filePath = Bundle.main.path(forResource: "classes", ofType: "txt"),
          let classes = try? String(contentsOfFile: filePath)
    else {
      fatalError("classes file was not found.")
    }
    return classes.split(whereSeparator: \.isNewline)
  }()
}
