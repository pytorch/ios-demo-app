//
//  NLPMachineTranslation.swift
//  PyTorchDemo
//
//  Created by Xiaofei Tang on 9/12/20.
//

import Foundation
import UIKit

class NLPMachineTranslation: Predictor {
    private var moduleEncoder: NLPTorchModule = {
        if let filePath = Bundle.main.path(forResource: "optimized_encoder_150k", ofType: "pth"),
            // the following caused fatal error, but ok on Android
            let module = NLPTorchModule(fileAtPath: filePath) {
            return module
        } else {
            fatalError("Failed to load model!")
        }
    }()
    
    private var moduleDecoder: NLPTorchModule = {
        if let filePath = Bundle.main.path(forResource: "optimized_decoder_150k", ofType: "pth"),
            let module = NLPTorchModule(fileAtPath: filePath) {
            return module
        } else {
            fatalError("Failed to load model!")
        }
    }()



    func translate(_ text: String) -> String {
        if text.isEmpty {
            return ""
        }
        guard let dict = moduleEncoder.encoderForward(text:text)
        else {
            fatalError("Failed to run encoder")
        }
        
        
        // TODO: how to let translate return 2 values - outputs and final hidden tensor
        print(dict)
        
        guard let result = moduleDecoder.decoderForward(dict:dict)
        else {
            fatalError("Failed to run decoder")
        }

        print(result)
        
        return result
    }
}
