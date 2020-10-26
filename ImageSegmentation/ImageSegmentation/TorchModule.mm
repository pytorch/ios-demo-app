// Copyright (c) 2020 Facebook, Inc. and its affiliates.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree.

#import "TorchModule.h"
#import "UIImageHelper.h"
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>
#import <LibTorch/LibTorch.h>

@implementation TorchModule {
@protected
    torch::jit::script::Module _impl;
}

- (nullable instancetype)initWithFileAtPath:(NSString*)filePath
{
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

- (unsigned char*)predictImage:(void*)imageBuffer
{
    try {
        int classnum = 21;
        int width = 800;
        int height = 800;

        at::Tensor tensor = torch::from_blob(imageBuffer, { 1, 3, width, height }, at::kFloat);

        torch::autograd::AutoGradMode guard(false);
        at::AutoNonVariableTypeMode non_var_type_mode(true);

        float* floatInput = tensor.data_ptr<float>();
        if (!floatInput) {
            return nil;
        }
        NSMutableArray* inputs = [[NSMutableArray alloc] init];
        for (int i = 0; i < 3 * width * height; i++) {
            [inputs addObject:@(floatInput[i])];
        }

        auto outputDict = _impl.forward({ tensor }).toGenericDict();

        auto outputTensor = outputDict.at("out").toTensor();

        float* floatBuffer = outputTensor.data_ptr<float>();
        if (!floatBuffer) {
            return nil;
        }
        NSMutableArray* results = [[NSMutableArray alloc] init];
        for (int i = 0; i < classnum * width * height; i++) {
            [results addObject:@(floatBuffer[i])];
        }

        unsigned char* buffer = (unsigned char*)malloc(3 * width * height);

        for (int j = 0; j < width; j++) {
            for (int k = 0; k < height; k++) {
                int maxj = 0;
                int maxk = 0;
                int maxi = 0;

                float maxnum = -100000.0;
                for (int i = 0; i < classnum; i++) {
                    if ([results[i * (width * height) + j * width + k] floatValue] > maxnum) {
                        maxnum = [results[i * (width * height) + j * width + k] floatValue];
                        maxj = j;
                        maxk = k;
                        maxi = i;
                    }
                }

                if (maxi == 15) {
                    buffer[3 * (maxj * width + maxk)] = 255;
                    buffer[3 * (maxj * width + maxk) + 1] = 0;
                    buffer[3 * (maxj * width + maxk) + 2] = 0;
                }

                else if (maxi == 17) {
                    buffer[3 * (maxj * width + maxk)] = 0;
                    buffer[3 * (maxj * width + maxk) + 1] = 0;
                    buffer[3 * (maxj * width + maxk) + 2] = 255;
                } else if (maxi == 13) {
                    buffer[3 * (maxj * width + maxk)] = 0;
                    buffer[3 * (maxj * width + maxk) + 1] = 255;
                    buffer[3 * (maxj * width + maxk) + 2] = 0;
                } else if (maxi == 8) {
                    buffer[3 * (maxj * width + maxk)] = 255;
                    buffer[3 * (maxj * width + maxk) + 1] = 0;
                    buffer[3 * (maxj * width + maxk) + 2] = 0;
                } else {
                    buffer[3 * (maxj * width + maxk)] = 0;
                    buffer[3 * (maxj * width + maxk) + 1] = 0;
                    buffer[3 * (maxj * width + maxk) + 2] = 0;
                }
            }
        }

        return buffer;
    } catch (const std::exception& exception) {
        NSLog(@"%s", exception.what());
    }
    return nil;
}

@end
