#import "TorchModule.h"
#import <LibTorch-Lite.h>

@implementation TorchModule {
@protected
  torch::jit::mobile::Module _model;
  at::Tensor _output;
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

@end

@implementation VisionTorchModule

- (float*)predictImage:(void*)imageBuffer {
  try {
    c10::InferenceMode guard(true);
    at::Tensor tensor = torch::from_blob(imageBuffer, {1, 3, 224, 224}, at::kFloat);
    _output = _model.forward({tensor}).toTensor();
    return _output.data_ptr<float>();
  } catch (const std::exception& exception) {
    NSLog(@"%s", exception.what());
  }
  return nil;
}

@end

@implementation NLPTorchModule

- (float*)predictText:(NSString*)text {
  try {
    c10::InferenceMode guard(true);
    const char* buffer = text.UTF8String;
    at::Tensor tensor = torch::from_blob((void*)buffer, {1, (int64_t)(strlen(buffer))}, at::kByte);
    _output = _model.forward({tensor}).toTensor();
    return _output.data_ptr<float>();
  } catch (const std::exception& exception) {
    NSLog(@"%s", exception.what());
  }
  return nil;
}

- (NSArray<NSString*>*)topics {
  try {
    auto genericList = _model.run_method("get_classes").toList();
    NSMutableArray<NSString*>* topics = [NSMutableArray<NSString*> new];
    for (int i = 0; i < genericList.size(); i++) {
      std::string topic = genericList.get(i).toString()->string();
      [topics addObject:[NSString stringWithCString:topic.c_str() encoding:NSUTF8StringEncoding]];
    }
    return [topics copy];
  } catch (const std::exception& exception) {
    NSLog(@"%s", exception.what());
  }
  return nil;
}

@end
