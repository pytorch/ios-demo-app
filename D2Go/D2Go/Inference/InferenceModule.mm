// Copyright (c) 2020 Facebook, Inc. and its affiliates.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree.

#import "InferenceModule.h"
#import <torch-nightly/LibTorch.h>

// 640x640 is the default image size used in the export.py in the yolov5 repo to export the TorchScript model, 25200*85 is the model output size
const int input_width = 640;
const int input_height = 640;
const int output_size = 25200*85;


@implementation InferenceModule {
    @protected torch::jit::script::Module _impl;
}

- (nullable instancetype)initWithFileAtPath:(NSString*)filePath {
    self = [super init];
    if (self) {
        try {
            _impl = torch::jit::load(filePath.UTF8String);
            _impl.eval();
        } catch (const std::exception& exception) {
            NSLog(@"%s", exception.what());
            return nil;
        }
    }
    return self;
}

- (NSArray<NSNumber*>*)detectImage:(void*)imageBuffer {
    try {
        at::Tensor tensor = torch::from_blob(imageBuffer, { 3, input_width, input_height }, at::kFloat);
        torch::autograd::AutoGradMode guard(false);
        at::AutoNonVariableTypeMode non_var_type_mode(true);
        
        std::vector<torch::Tensor> v;
        v.push_back(tensor);
        
        auto outputTuple = _impl.forward({ at::TensorList(v) }).toTuple();
        
        // TODO: fix Expected Tensor but got GenericList
        auto outputDict = outputTuple->elements()[1].toList().get(0).toGenericDict();
        auto boxesTensor = outputDict.at("boxes").toTensor();
        auto scoresTensor = outputDict.at("scores").toTensor();
        auto labelsTensor = outputDict.at("labels").toTensor();

        float* boxesBuffer = boxesTensor.data_ptr<float>();
        if (!boxesBuffer) {
            return nil;
        }
        float* scoresBuffer = scoresTensor.data_ptr<float>();
        if (!scoresBuffer) {
            return nil;
        }
        long* labelsBuffer = labelsTensor.data_ptr<long>();
        if (!labelsBuffer) {
            return nil;
        }
        
        NSMutableArray* results = [[NSMutableArray alloc] init];
        long num = scoresTensor.numel();
        for (int i = 0; i < num; i++) {
            if (scoresBuffer[i] < 0.5)
                continue;

            [results addObject:@(boxesBuffer[4 * i])];
            [results addObject:@(boxesBuffer[4 * i + 1])];
            [results addObject:@(boxesBuffer[4 * i + 2])];
            [results addObject:@(boxesBuffer[4 * i + 3])];
            [results addObject:@(scoresBuffer[i])];
            [results addObject:@(labelsBuffer[i])];
        }
        
        return [results copy];
        
        
        
        return nil;
        
    } catch (const std::exception& exception) {
        NSLog(@"%s", exception.what());
    }
    return nil;
}

@end
