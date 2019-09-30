#import "TorchModule.h"
#import <Foundation/Foundation.h>
#import <torch/script.h>

@implementation TorchModule {
 @protected
  torch::jit::script::Module _impl;
}

+ (nullable instancetype)loadModel:(NSString*)modelPath {
  if (modelPath.length == 0) {
    return nil;
  }
  @try {
    TorchModule* module = [[self.class alloc] init];
    auto qengines = at::globalContext().supportedQEngines();
    if (std::find(qengines.begin(), qengines.end(), at::QEngine::QNNPACK) != qengines.end()) {
      at::globalContext().setQEngine(at::QEngine::QNNPACK);
    }
    at::AutoNonVariableTypeMode non_var_type_mode(true);
    module->_impl = torch::jit::load(modelPath.UTF8String);
    module->_impl.eval();
    return module;
  } @catch (NSException* exception) {
    @throw exception;
    NSLog(@"%@", exception);
  }
  return nil;
}

@end

@implementation VisionTorchModule

- (NSArray<NSNumber*>*)predictImage:(void*)imageBuffer {
  @try {
    at::Tensor tensor = torch::from_blob((void*)imageBuffer, {1, 3, 224, 224}, at::kFloat);
    torch::autograd::AutoGradMode guard(false);
    at::AutoNonVariableTypeMode non_var_type_mode(true);
    auto outputTensor = _impl.forward({tensor}).toTensor();
    void* tensorBuffer = outputTensor.storage().data();
    if (!tensorBuffer) {
      return nil;
    }
    NSMutableArray* results = [[NSMutableArray alloc] init];
    float* floatBuffer = (float*)tensorBuffer;
    for (int i = 0; i < 1000; i++) {
      [results addObject:@(floatBuffer[i])];
    }
    return [results copy];
  } @catch (NSException* exception) {
    @throw exception;
    NSLog(@"%@", exception);
  }
  return nil;
}

@end

@implementation NLPTorchModule

- (NSArray<NSNumber*>*)predictText:(NSString*)text {
  @try {
    uint8_t* buffer = (uint8_t*)text.UTF8String;
    torch::autograd::AutoGradMode guard(false);
    at::AutoNonVariableTypeMode non_var_type_mode(true);
    at::Tensor tensor = torch::from_blob((void*)buffer, {1, (int64_t)(text.length)}, at::kByte);
    auto outputTensor = _impl.forward({tensor}).toTensor();
    void* tensorBuffer = outputTensor.storage().data();
    if (!tensorBuffer) {
      return nil;
    }
    NSMutableArray* results = [[NSMutableArray alloc] init];
    float* floatBuffer = (float*)tensorBuffer;
    for (int i = 0; i < 16; i++) {
      [results addObject:@(floatBuffer[i])];
    }
    return [results copy];
  } @catch (NSException* exception) {
    @throw exception;
    NSLog(@"%@", exception);
  }
  return nil;
}

- (NSArray<NSString*>*)topics {
  @try {
    auto genericList = _impl.run_method("get_classes").toGenericList();
    NSMutableArray<NSString*>* topics = [NSMutableArray<NSString*> new];
    for (int i = 0; i < genericList.size(); i++) {
      std::string topic = genericList.get(i).toString()->string();
      [topics addObject:[NSString stringWithCString:topic.c_str() encoding:NSUTF8StringEncoding]];
    }
    return [topics copy];
  } @catch (NSException* exception) {
    @throw exception;
    NSLog(@"%@", exception);
  }
  return nil;
}

@end
