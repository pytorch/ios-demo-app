// Copyright (c) 2020 Facebook, Inc. and its affiliates.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree.


#import "InferenceModule.h"
#import <LibTorch/LibTorch.h>

const int MNIST_IMAGE_SIZE = 28;
const int MODEL_OUTPUT_SIZE = 10;

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
    for (int j = 0; j < MODEL_OUTPUT_SIZE; j++) {
      if ([array[j] floatValue]> maxVal) {
          maxVal = [array[j] floatValue];
          maxIdx = j;
      }
    }
    return maxIdx;
}


- (NSString *)recognize:(NSArray*)points {
    
    try {
        int input_length = MNIST_IMAGE_SIZE * MNIST_IMAGE_SIZE;
        float inputs[input_length];
        
        for (int i=0; i<points.count; i++)
            inputs[i] = [points[i] floatValue];
        
        at::Tensor tensorInputs = torch::from_blob((void*)inputs, {1, 1, MNIST_IMAGE_SIZE, MNIST_IMAGE_SIZE}, at::kFloat);
        
        torch::autograd::AutoGradMode guard(false);
        at::AutoNonVariableTypeMode non_var_type_mode(true);
    
        auto outputTensor = _impl.forward({ tensorInputs }).toTensor();
        float* outBuffer = outputTensor.data_ptr<float>();
        if (!outBuffer) {
            return nil;
        }
        NSMutableArray* outputs = [[NSMutableArray alloc] init];
        for (int i = 0; i < MODEL_OUTPUT_SIZE; i++) {
            [outputs addObject:@(outBuffer[i])];
        }

        return [NSString stringWithFormat:@"%d", [self argMax:outputs]];
    }
    catch (const std::exception& exception) {
        NSLog(@"%s", exception.what());
    }
    return nil;
}


@end
