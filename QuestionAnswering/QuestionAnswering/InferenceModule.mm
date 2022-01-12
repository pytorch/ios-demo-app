// Copyright (c) 2020 Facebook, Inc. and its affiliates.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree.


#import "InferenceModule.h"
#import <Libtorch-Lite/Libtorch-Lite.h>

const int MODEL_INPUT_LENGTH = 360;

@implementation InferenceModule {
    
    @protected torch::jit::mobile::Module _impl;
}

- (nullable instancetype)initWithFileAtPath:(NSString*)filePath {
    self = [super init];
    if (self) {
        try {
            auto qengines = at::globalContext().supportedQEngines();
            if (std::find(qengines.begin(), qengines.end(), at::QEngine::QNNPACK) != qengines.end()) {
                at::globalContext().setQEngine(at::QEngine::QNNPACK);
            }
            _impl = torch::jit::_load_for_mobile(filePath.UTF8String);
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


- (NSArray<NSNumber*>*)answer:(NSArray*)tokenIds {
    
    try {
        long inputs[MODEL_INPUT_LENGTH];
        for (int i = 0; i < MODEL_INPUT_LENGTH; i++)
            inputs[i] = 0;
        for (int i=0; i<tokenIds.count; i++)
            inputs[i] = [tokenIds[i] longValue];
        at::Tensor tensorInputs = torch::from_blob((void*)inputs, {1, MODEL_INPUT_LENGTH}, at::kLong);
        
        c10::InferenceMode guard;
        
        CFTimeInterval startTime = CACurrentMediaTime();
        auto outputDict = _impl.forward({ tensorInputs }).toGenericDict();
        CFTimeInterval elapsedTime = CACurrentMediaTime() - startTime;
        NSLog(@"inference time:%f", elapsedTime);


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

        int start = [self argMax:startLogits];
        int end = [self argMax:endLogits];

        NSMutableArray* results = [[NSMutableArray alloc] init];
        for (int i = start; i <= end; i++)
            [results addObject:tokenIds[i]];
        
        return results;
    }
    catch (const std::exception& exception) {
        NSLog(@"%s", exception.what());
    }
    return nil;
}


@end
