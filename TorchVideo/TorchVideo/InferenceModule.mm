// Copyright (c) 2020 Facebook, Inc. and its affiliates.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree.

#import "InferenceModule.h"
#import <Libtorch-Lite/Libtorch-Lite.h>

const int INPUT_WIDTH = 160;
const int INPUT_HEIGHT = 160;
const int OUTPUT_SIZE = 400;
const int TOP_COUNT = 5;


@implementation InferenceModule {
@protected torch::jit::mobile::Module _model;
@protected at::Tensor _output;
}

- (nullable instancetype)initWithFileAtPath:(NSString*)filePath {
  self = [super init];
  if (self) {
    try {
      _model = torch::jit::_load_for_mobile(filePath.UTF8String);
    } catch (const std::exception& exception) {
      NSLog(@"%s", exception.what());
      return nil;
    }
  }
  return self;
}

- (float*)classifyFrames:(void*)framesBuffer {
  try {
    c10::InferenceMode guard;
    at::Tensor tensor = torch::from_blob(framesBuffer, { 1, 3, 4, INPUT_WIDTH, INPUT_HEIGHT }, at::kFloat);
    _output = _model.forward({ tensor }).toTensor();
    return _output.data_ptr<float>();
  } catch (const std::exception& exception) {
    NSLog(@"%s", exception.what());
  }
  return nil;
}

@end
