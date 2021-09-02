// Copyright (c) 2020 Facebook, Inc. and its affiliates.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree.

#import "TorchModule.h"
#import "UIImageHelper.h"
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>
#import <Libtorch-Lite/Libtorch-Lite.h>

@implementation TorchModule {
@protected
    torch::jit::mobile::Module _impl;
}

- (nullable instancetype)initWithFileAtPath:(NSString*)filePath {
    self = [super init];
    if (self) {
        try {
            _impl = torch::jit::_load_for_mobile(filePath.UTF8String);
        } catch (const std::exception& exception) {
            NSLog(@"%s", exception.what());
            return nil;
        }
    }
    return self;
}

- (unsigned char*)segmentImage:(void *)imageBuffer withWidth:(int)width withHeight:(int)height {
    try {
        
        // see http://host.robots.ox.ac.uk:8080/pascal/VOC/voc2007/segexamples/index.html for the list of classes with indexes
        const int CLASSNUM = 21;
        const int DOG = 12;
        const int PERSON = 15;
        const int SHEEP = 17;

        at::Tensor tensor = torch::from_blob(imageBuffer, { 1, 3, width, height }, at::kFloat);

        float* floatInput = tensor.data_ptr<float>();
        if (!floatInput) {
            return nil;
        }
        NSMutableArray* inputs = [[NSMutableArray alloc] init];
        for (int i = 0; i < 3 * width * height; i++) {
            [inputs addObject:@(floatInput[i])];
        }

        c10::InferenceMode guard;
        
        CFTimeInterval startTime = CACurrentMediaTime();
        auto outputDict = _impl.forward({ tensor }).toGenericDict();
        CFTimeInterval elapsedTime = CACurrentMediaTime() - startTime;
        NSLog(@"inference time:%f", elapsedTime);
        
        auto outputTensor = outputDict.at("out").toTensor();

        float* floatBuffer = outputTensor.data_ptr<float>();
        if (!floatBuffer) {
            return nil;
        }
        NSMutableArray* results = [[NSMutableArray alloc] init];
        for (int i = 0; i < CLASSNUM * width * height; i++) {
            [results addObject:@(floatBuffer[i])];
        }

        NSMutableData* data = [NSMutableData dataWithLength:sizeof(unsigned char) * 3 * width * height];
        unsigned char* buffer = (unsigned char*)[data mutableBytes];
        // go through each element in the output of size [WIDTH, HEIGHT] and
        // set different color for different classnum
        for (int j = 0; j < width; j++) {
            for (int k = 0; k < height; k++) {
                int maxi = 0, maxj = 0, maxk = 0;
                float maxnum = -100000.0;
                for (int i = 0; i < CLASSNUM; i++) {
                    if ([results[i * (width * height) + j * width + k] floatValue] > maxnum) {
                        maxnum = [results[i * (width * height) + j * width + k] floatValue];
                        maxi = i; maxj = j; maxk = k;
                    }
                }

                int n = 3 * (maxj * width + maxk);
                // color coding for person (red), dog (green), sheep (blue)
                // black color for background and other classes
                buffer[n] = 0; buffer[n+1] = 0; buffer[n+2] = 0;
                if (maxi == PERSON) buffer[n] = 255;
                else if (maxi == DOG) buffer[n+1] = 255;
                else if (maxi == SHEEP) buffer[n+2] = 255;
            }
        }

        return buffer;
    } catch (const std::exception& exception) {
        NSLog(@"%s", exception.what());
    }
    return nil;
}

@end
