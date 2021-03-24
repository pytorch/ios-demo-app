// Copyright (c) 2020 Facebook, Inc. and its affiliates.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree.

#import "InferenceModule.h"
#import <LibTorch/LibTorch.h>

const int INPUT_WIDTH = 160;
const int INPUT_HEIGHT = 160;
const int OUTPUT_SIZE = 400;
const int TOP_COUNT = 5;


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

- (int)argMax:(NSArray*)array {
    int maxIdx = 0;
    float maxVal = -FLT_MAX;
    for (int j = 0; j < OUTPUT_SIZE; j++) {
      if ([array[j] floatValue]> maxVal) {
          maxVal = [array[j] floatValue];
          maxIdx = j;
      }
    }
    return maxIdx;
}


NSComparisonResult customCompareFunction(NSArray* first, NSArray* second, void* context)
{
    id firstValue = [first objectAtIndex:0];
    id secondValue = [second objectAtIndex:0];
    return [firstValue compare:secondValue];
}


- (NSArray<NSNumber*>*)classifyFrames:(void*)framesBuffer {
    try {
        at::Tensor tensor = torch::from_blob(framesBuffer, { 1, 3, 4, INPUT_WIDTH, INPUT_HEIGHT }, at::kFloat);
        torch::autograd::AutoGradMode guard(false);
        at::AutoNonVariableTypeMode non_var_type_mode(true);
        
        auto outputTensor = _impl.forward({ tensor }).toTensor();

        float* floatBuffer = outputTensor.data_ptr<float>();
        if (!floatBuffer) {
            return nil;
        }
        
        NSMutableArray* scores = [[NSMutableArray alloc] init];
        for (int i = 0; i < OUTPUT_SIZE; i++) {
          [scores addObject:@(floatBuffer[i])];
        }
        
        NSMutableArray* scoresIdx = [[NSMutableArray alloc] init];
        for (int i = 0; i < OUTPUT_SIZE; i++) {
          [scoresIdx addObject:[NSArray arrayWithObjects:scores[i], @(i)]];
        }
        
        NSArray* sortedScoresIdx = [scoresIdx sortedArrayUsingFunction:customCompareFunction context:NULL];

        
//        NSArray *sortedScores = [[[scores sortedArrayUsingSelector: @selector(compare:)] reverseObjectEnumerator] allObjects];
        
        NSMutableArray* results = [[NSMutableArray alloc] init];
        for (int i = 0; i < TOP_COUNT; i++)
            [results addObject: sortedScoresIdx[i]];
        
        return [results copy];
        
    } catch (const std::exception& exception) {
        NSLog(@"%s", exception.what());
    }
    return nil;
}

@end
