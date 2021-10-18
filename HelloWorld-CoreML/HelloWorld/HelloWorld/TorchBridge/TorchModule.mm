#import "TorchModule.h"
#import <Libtorch-Lite-Nightly/Libtorch-Lite.h>
#include <caffe2/core/timer.h>

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

- (NSArray<NSNumber*>*)predictImage:(void*)imageBuffer {
  try {
    at::Tensor tensor = torch::from_blob(imageBuffer, {1, 3, 224, 224}, at::kFloat);
    c10::InferenceMode guard;
    caffe2::Timer t;
    auto outputTensor = _impl.forward({tensor}).toTensor().cpu();
    std::cout << "forward took: " << t.MilliSeconds() << std::endl;
    float* floatBuffer = outputTensor.data_ptr<float>();
    if (!floatBuffer) {
      return nil;
    }
    NSMutableArray* results = [[NSMutableArray alloc] init];
    for (int i = 0; i < 1000; i++) {
      [results addObject:@(floatBuffer[i])];
    }
    return [results copy];
  } catch (const std::exception& exception) {
    NSLog(@"%s", exception.what());
  }
  return nil;
}

@end

