#import "TorchModule.h"
#import <LibTorch/LibTorch.h>

@implementation TorchModule {
 @protected
  torch::jit::script::Module _impl;
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
    at::Tensor tensor = torch::from_blob(imageBuffer, {1, 3, 640, 640}, at::kFloat);
    torch::autograd::AutoGradMode guard(false);
    at::AutoNonVariableTypeMode non_var_type_mode(true);
      
      float* inputBuffer = tensor.data_ptr<float>();
      if (!inputBuffer) {
        return nil;
      }
      NSMutableArray* inputs = [[NSMutableArray alloc] init];
      for (int i = 0; i < tensor.numel(); i++) {
        [inputs addObject:@(inputBuffer[i])];
      }

      
      auto outputTuple = _impl.forward({tensor}).toTuple();

      auto predTensor = outputTuple->elements()[0].toTensor();
//      (lldb) po predTensor.dim()
//      3
      
      /*
      at::IntArrayRef aa = predTensor.sizes();
      aa.data();
      int64_t n = predTensor.numel(); // 2142000
      size_t ss = aa.size();

      auto outputList = outputTuple->elements()[1].toList();
      auto outputTensor = outputList.get(0).toTensor();
      int64_t n2 = outputTensor.numel(); //1632000

//      (lldb) po outputList.get(0).toTensor().dim()
//      5
//
//      (lldb) po outputList.get(1).toTensor().dim()
//      5
//
//      (lldb) po outputList.get(2).toTensor().dim()
//      5
      
//      torch.Size([1, 3, 512, 640])
//      torch.Size([1, 20160, 85]) # predict 3 boxes at each scale so the tensor is N × N × [3 ∗ (4 + 1 + 80)] for the 4 bounding box offsets, 1 objectness prediction, and 80 class predictions.
//      torch.Size([1, 3, 64, 80, 85])
//      torch.Size([1, 3, 32, 40, 85])
//      torch.Size([1, 3, 16, 20, 85])

      
      
      int64_t d = outputTensor.dim(); // 5
      at::IntArrayRef a = outputTensor.sizes();
      size_t s = a.size();*/
      
    float* floatBuffer = predTensor.data_ptr<float>();
    if (!floatBuffer) {
      return nil;
    }
    NSMutableArray* results = [[NSMutableArray alloc] init];
    // for any input image, predTensor.numel() returns 214200
    // for 640x640 image.png, the predTensor (output[0]) in Python has the
    // shape (1, 25200, 85)
    //for (int i = 0; i < predTensor.numel(); i++) {
    for (int i = 0; i < 25200*85; i++) {
      [results addObject:@(floatBuffer[i])];
    }
    return [results copy];
  } catch (const std::exception& exception) {
    NSLog(@"%s", exception.what());
  }
  return nil;
}

@end

