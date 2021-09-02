// Copyright (c) 2020 Facebook, Inc. and its affiliates.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree.

#import "InferenceModule.h"
#import <Libtorch-Lite/Libtorch-Lite.h>

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

- (NSString*)decoderForward:(NSDictionary*)dict {
    try {
        // to be consistent with the model inputs defined in seq2seq_nmt.py, based on
        // https://pytorch.org/tutorials/intermediate/seq2seq_translation_tutorial.html
        const int EOS_TOKEN = 1;
        const int HIDDEN_SIZE = 256;
        const int MAX_LENGTH = 50;
        const int TARGET_LANG_VOC_SIZE = 13038; // ENGLISH

        NSArray *arrayHidden = dict[@"hidden"];
        float hidden[HIDDEN_SIZE];
        for (int i=0; i<HIDDEN_SIZE; i++)
            hidden[i] = [arrayHidden[i] floatValue];
        at::Tensor tensorHidden = torch::from_blob((void*)hidden, {1, 1, HIDDEN_SIZE}, at::kFloat);
        
        NSArray *arrayOutputs = dict[@"outputs"];
        float outputs[MAX_LENGTH*HIDDEN_SIZE];
        for (int i=0; i<MAX_LENGTH*HIDDEN_SIZE; i++)
            outputs[i] =  [arrayOutputs[i] floatValue];
        at::Tensor tensorOutputs = torch::from_blob((void*)outputs, {MAX_LENGTH, HIDDEN_SIZE}, at::kFloat);

        torch::Tensor tensorOutput;
        c10::InferenceMode guard;
        
        long input[1]  = {0};
        at::Tensor tensorInput = torch::from_blob((void*)(&input[0]), {1, 1}, at::kLong);
        NSMutableArray<NSNumber*>* arrayTops = [[NSMutableArray alloc] init];
        for (int i=0; i< MAX_LENGTH; i++) {
            auto outputTuple = _impl.forward({tensorInput, tensorHidden, tensorOutputs}).toTuple();
            
            tensorHidden = outputTuple->elements()[1].toTensor();
            tensorOutput = outputTuple->elements()[0].toTensor();
            float* floatBufferOutput = tensorOutput.data_ptr<float>();

            int topIdx = 0;
            float topVal = -FLT_MAX;
            for (int j=0; j<TARGET_LANG_VOC_SIZE; j++) {
              if (floatBufferOutput[j] > topVal) {
                  topVal = floatBufferOutput[j];
                  topIdx = j;
              }
            }
            if (topIdx == EOS_TOKEN)
                break;
            [arrayTops addObject:@(topIdx)];
            input[0] = topIdx;
            tensorInput = torch::from_blob((void*)(&input[0]), {1, 1}, at::kLong);
        }

        NSError * error=nil;
        NSString *filepath = [[NSBundle mainBundle] pathForResource:@"target_idx2wrd" ofType:@"json"];
        NSData *jsonData = [NSData dataWithContentsOfFile:filepath];
        NSDictionary * idx2wrd = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];

        NSString *result = @"";
        for (NSNumber *top in arrayTops) {
            result = [NSString stringWithFormat:@"%@ %@", result, [idx2wrd objectForKey:[top stringValue]]];
        }
        return result;
    }
    catch (const std::exception& exception) {
        NSLog(@"%s", exception.what());
    }
    return @"";
}

- (NSDictionary*)encoderForward:(NSString*)text {
    const int HIDDEN_SIZE = 256;
    const int MAX_LENGTH = 50;
    
    try {
        NSString *filepath = [[NSBundle mainBundle] pathForResource:@"source_wrd2idx" ofType:@"json"];
        NSData *jsonData = [NSData dataWithContentsOfFile:filepath];
        NSDictionary *wrd2idx = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:nil];

        NSArray *words = [text componentsSeparatedByString:@" "];
        long inputs[MAX_LENGTH];
        for (int i = 0; i < words.count; i++) {
            inputs[i] = [[wrd2idx objectForKey:words[i]] intValue];
        }
      
        float hidden[HIDDEN_SIZE];
        for (int i=0; i<HIDDEN_SIZE; i++)
            hidden[i] = 0.0;
        at::Tensor tensorHidden = torch::from_blob((void*)hidden, {1, 1, HIDDEN_SIZE}, at::kFloat);

        torch::autograd::AutoGradMode guard(false);
        at::AutoNonVariableTypeMode non_var_type_mode(true);
        torch::Tensor tensorOutput;
    
        float outputs[MAX_LENGTH*HIDDEN_SIZE];
        for (int i=0; i<MAX_LENGTH*HIDDEN_SIZE; i++)
            outputs[i] =  0.0;
        at::Tensor tensorOutputs = torch::from_blob((void*)outputs, {MAX_LENGTH, HIDDEN_SIZE}, at::kFloat);

        for (int i=0; i<words.count; i++) {
            at::Tensor tensorInput = torch::from_blob((void*)(&inputs[i]), {1}, at::kLong);
            auto outputTuple = _impl.forward({tensorInput, tensorHidden}).toTuple();
              
            tensorOutput = outputTuple->elements()[0].toTensor();
            float* floatBufferOutput = tensorOutput.data_ptr<float>();
            for (int j=0; j<HIDDEN_SIZE; j++) outputs[i*HIDDEN_SIZE+j]=floatBufferOutput[j];
            tensorHidden = outputTuple->elements()[1].toTensor();
        }
    
        float* floatBufferHidden = tensorHidden.data_ptr<float>();
        NSMutableArray* arrayHidden = [[NSMutableArray alloc] init];
        for (int i = 0; i < HIDDEN_SIZE; i++) {
            [arrayHidden addObject:@(floatBufferHidden[i])];
        }
      
        NSMutableArray* arrayOutputs = [[NSMutableArray alloc] init];
        for (int i = 0; i < MAX_LENGTH*HIDDEN_SIZE; i++) {
            [arrayOutputs addObject:@(outputs[i])];
        }
        NSDictionary* dict = @{ @"outputs": arrayOutputs, @"hidden": arrayHidden };
        return [dict copy];
    }
    catch (const std::exception& exception) {
        NSLog(@"%s", exception.what());
    }
    return nil;
}

@end
