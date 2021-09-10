// Copyright (c) 2020 Facebook, Inc. and its affiliates.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree.

import Foundation
import UIKit


class MachineTranslation {
    private var moduleEncoder: InferenceModule = {
        if let filePath = Bundle.main.path(forResource: "optimized_encoder_150k", ofType: "ptl"),
            let module = InferenceModule(fileAtPath: filePath) {
            return module
        } else {
            fatalError("Failed to load model!")
        }
    }()
    
    private var moduleDecoder: InferenceModule = {
        if let filePath = Bundle.main.path(forResource: "optimized_decoder_150k", ofType: "ptl"),
            let module = InferenceModule(fileAtPath: filePath) {
            return module
        } else {
            fatalError("Failed to load model!")
        }
    }()

    func translate(_ text: String) -> String {
        if text.isEmpty {
            return ""
        }
        
        let startTime = CACurrentMediaTime()

        guard let dict = moduleEncoder.encoderForward(text:text)
        else {
            fatalError("Failed to run encoder")
        }
                
        guard let result = moduleDecoder.decoderForward(dict:dict)
        else {
            fatalError("Failed to run decoder")
        }
        
        let inferenceTime = CACurrentMediaTime() - startTime
        print("inferenceTime: ", inferenceTime)

        return result
    }
}
