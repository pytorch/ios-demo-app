// Copyright (c) 2020 Facebook, Inc. and its affiliates.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree.


#import "InferenceModule.h"
#import <LibTorch/LibTorch.h>
#import <AVFoundation/AVAudioRecorder.h>
#import <AVFoundation/AVAudioSettings.h>
#import <AVFoundation/AVAudioSession.h>
#import <AudioToolbox/AudioToolbox.h>


const int MODEL_INPUT_LENGTH = 65024;
const NSString *TOKENS[] = {@"<s>", @"<pad>", @"</s>", @"<unk>", @"|", @"E", @"T", @"A", @"O", @"N", @"I", @"H", @"S", @"R", @"D", @"L", @"U", @"M", @"W", @"C", @"F", @"G", @"Y", @"P", @"B", @"V", @"K", @"'", @"X", @"J", @"Q", @"Z"};

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
    for (int j = 0; j < [array count]; j++) {
      if ([array[j] floatValue]> maxVal) {
          maxVal = [array[j] floatValue];
          maxIdx = j;
      }
    }
    return maxIdx;
}


- (NSString*)recognize:(void*)wavBuffer {
    try {
        at::Tensor tensorInputs = torch::from_blob((void*)wavBuffer, {1, MODEL_INPUT_LENGTH}, at::kFloat);
        
        float* floatInput = tensorInputs.data_ptr<float>();
        if (!floatInput) {
            return nil;
        }
        NSMutableArray* inputs = [[NSMutableArray alloc] init];
        for (int i = 0; i < MODEL_INPUT_LENGTH; i++) {
            [inputs addObject:@(floatInput[i])];
        }
        
        
        torch::autograd::AutoGradMode guard(false);
        at::AutoNonVariableTypeMode non_var_type_mode(true);
    
        auto outputDict = _impl.forward({ tensorInputs }).toGenericDict();

        auto logitsTensor = outputDict.at("logits").toTensor();
        float* logitsBuffer = logitsTensor.data_ptr<float>();
        if (!logitsBuffer) {
            return nil;
        }
        
        NSUInteger TOKEN_LENGTH = (NSUInteger) (sizeof(TOKENS) / sizeof(NSString*));
        int64_t output_len = logitsTensor.numel();
        NSMutableArray* logits = [[NSMutableArray alloc] init];
        NSString *result = @"";
        for (int i = 0; i < output_len; i++) {
            // for every 32 output values, get the argmax and its token
            if (i > 0 && i % TOKEN_LENGTH == 0) {
                int tid = [self argMax:logits];
                if (tid > 4)
                    result = [NSString stringWithFormat:@"%@ %@", result, TOKENS[tid]];
                
                [logits removeAllObjects];
                [logits addObject:@(logitsBuffer[i])];
            }
            else {
                [logits addObject:@(logitsBuffer[i])];
            }
        }
        
        return result;
    }
    catch (const std::exception& exception) {
        NSLog(@"%s", exception.what());
    }
    return nil;
}


@end
