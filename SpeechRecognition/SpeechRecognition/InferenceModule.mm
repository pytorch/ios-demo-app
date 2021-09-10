// Copyright (c) 2020 Facebook, Inc. and its affiliates.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree.


#import "InferenceModule.h"
#import <Libtorch-Lite/Libtorch-Lite.h>
#import <AVFoundation/AVAudioRecorder.h>
#import <AVFoundation/AVAudioSettings.h>
#import <AVFoundation/AVAudioSession.h>
#import <AudioToolbox/AudioToolbox.h>


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


- (NSString*)recognize:(void*)wavBuffer bufLength:(int)bufLength{
    try {
        at::Tensor tensorInputs = torch::from_blob((void*)wavBuffer, {1, bufLength}, at::kFloat);
        
        float* floatInput = tensorInputs.data_ptr<float>();
        if (!floatInput) {
            return nil;
        }
        NSMutableArray* inputs = [[NSMutableArray alloc] init];
        for (int i = 0; i < bufLength; i++) {
            [inputs addObject:@(floatInput[i])];
        }
        
        c10::InferenceMode guard;
        
        CFTimeInterval startTime = CACurrentMediaTime();
        auto result = _impl.forward({ tensorInputs }).toStringRef();
        CFTimeInterval elapsedTime = CACurrentMediaTime() - startTime;
        NSLog(@"inference time:%f", elapsedTime);
            
        return [NSString stringWithCString:result.c_str() encoding:[NSString defaultCStringEncoding]];
    }
    catch (const std::exception& exception) {
        NSLog(@"%s", exception.what());
    }
    return nil;
}


@end
