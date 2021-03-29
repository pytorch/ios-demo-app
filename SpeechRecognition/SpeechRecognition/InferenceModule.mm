// Copyright (c) 2020 Facebook, Inc. and its affiliates.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree.


#import "InferenceModule.h"
#import <LibTorch/LibTorch.h>

const int MODEL_INPUT_LENGTH = 360;

@implementation InferenceModule {
    
    @protected torch::jit::script::Module _impl;
}

- (nullable instancetype)initWithFileAtPath:(NSString*)filePath {
    self = [super init];
    if (self) {
        try {
            auto qengines = at::globalContext().supportedQEngines();
            if (std::find(qengines.begin(), qengines.end(), at::QEngine::QNNPACK) != qengines.end()) {
                at::globalContext().setQEngine(at::QEngine::QNNPACK);
            }
            _impl = torch::jit::load(filePath.UTF8String);
            _impl.eval();
        }
        catch (const std::exception& exception) {
            NSLog(@"%s", exception.what());
            return nil;
        }
    }
    return self;
}

- (int)argMax:(NSArray*)array {
    int maxIdx = 0;
    float maxVal = -FLT_MAX;
    for (int j = 0; j < MODEL_INPUT_LENGTH; j++) {
      if ([array[j] floatValue]> maxVal) {
          maxVal = [array[j] floatValue];
          maxIdx = j;
      }
    }
    return maxIdx;
}


- (unsigned char*)recognize:(void*)wavBuffer {
    
    try {
        long inputs[MODEL_INPUT_LENGTH];
        for (int i = 0; i < MODEL_INPUT_LENGTH; i++)
            inputs[i] = 0;
        at::Tensor tensorInputs = torch::from_blob((void*)inputs, {1, MODEL_INPUT_LENGTH}, at::kLong);
        
        torch::autograd::AutoGradMode guard(false);
        at::AutoNonVariableTypeMode non_var_type_mode(true);
    
        auto outputDict = _impl.forward({ tensorInputs }).toGenericDict();

        auto startTensor = outputDict.at("start_logits").toTensor();
        float* startBuffer = startTensor.data_ptr<float>();
        if (!startBuffer) {
            return nil;
        }
        NSMutableArray* startLogits = [[NSMutableArray alloc] init];
        for (int i = 0; i < MODEL_INPUT_LENGTH; i++) {
            [startLogits addObject:@(startBuffer[i*2])]; // *2 - unique in the iOS implementation
        }
        
        auto endTensor = outputDict.at("end_logits").toTensor();
        float* endBuffer = endTensor.data_ptr<float>();
        if (!endBuffer) {
            return nil;
        }
        NSMutableArray* endLogits = [[NSMutableArray alloc] init];
        for (int i = 0; i < MODEL_INPUT_LENGTH; i++) {
            [endLogits addObject:@(endBuffer[i*2])];
        }


        NSMutableArray* results = [[NSMutableArray alloc] init];
        
        return nil;
    }
    catch (const std::exception& exception) {
        NSLog(@"%s", exception.what());
    }
    return nil;
}


@end
