#import "TorchModule.h"
#import <LibTorch-Lite-Nightly/LibTorch-Lite.h>

@implementation TorchModule {
 @protected
  torch::jit::mobile::Module _model;
  at::Tensor _output;
  int64_t _inputSize[4];
}

- (nullable instancetype)initWithFileAtPath:(NSString*)filePath width:(long)width height:(long)height {
  self = [super init];
  if (self) {
    _inputSize[0] = 1;
    _inputSize[1] = 3;
    _inputSize[2] = width;
    _inputSize[3] = height;
    try {
      _model = torch::jit::_load_for_mobile(filePath.UTF8String);
    } catch (const std::exception& exception) {
      NSLog(@"%s", exception.what());
      return nil;
    }
  }
  return self;
}

- (float*)predictImage:(void*)imageBuffer {
  try {
    c10::InferenceMode guard(true);
    at::Tensor tensor = torch::from_blob(imageBuffer, _inputSize, at::kFloat).metal();
    _output = _model.forward({tensor}).toTensor().cpu();
    return _output.data_ptr<float>();
  } catch (const std::exception& exception) {
    NSLog(@"%s", exception.what());
  }
  return nil;
}

@end

