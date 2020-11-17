#import "TorchModule.h"
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

- (NSArray<NSNumber*>*)detectImage:(void*)imageBuffer
{
    try {
        // 640x640 is the default image size used in the export.py in the yolov5 repo to export the TorchScript model
        at::Tensor tensor = torch::from_blob(imageBuffer, { 1, 3, 640, 640 }, at::kFloat);
        torch::autograd::AutoGradMode guard(false);
        at::AutoNonVariableTypeMode non_var_type_mode(true);
        
        float* floatInput = tensor.data_ptr<float>();
        if (!floatInput) {
            return nil;
        }
        NSMutableArray* inputs = [[NSMutableArray alloc] init];
        for (int i = 0; i < 3 * 640 * 640; i++) {
            [inputs addObject:@(floatInput[i])];
        }

        

        auto outputTuple = _impl.forward({ tensor }).toTuple();

        auto predTensor = outputTuple->elements()[0].toTensor();

        float* floatBuffer = predTensor.data_ptr<float>();
        if (!floatBuffer) {
            return nil;
        }
        NSMutableArray* results = [[NSMutableArray alloc] init];

        // (1, 25200, 85) is the output size when running detect.py with an input image of size 640x640 from the yolov5 repo. See README.md for more info.
        for (int i = 0; i < 25200 * 85; i++) {
            [results addObject:@(floatBuffer[i])];
        }
        return [results copy];
    } catch (const std::exception& exception) {
        NSLog(@"%s", exception.what());
    }
    return nil;
}

@end
