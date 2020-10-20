// Copyright (c) 2020 Facebook, Inc. and its affiliates.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree.



#import "TorchModule.h"
#import <LibTorch/LibTorch.h>
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>
#import <UIKit/UIKit.h>

@implementation TorchModule {
 @protected
  torch::jit::script::Module _impl;
}

UIImageView* m_imageView;

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

- (void)setImageView:(UIImageView*)imageView {
    m_imageView = imageView;
}

- (NSArray<NSNumber*>*)predictImage:(void*)imageBuffer {
    try {
      int classnum = 21;
      int width = 179;
      int height = 179;
 
    at::Tensor tensor = torch::from_blob(imageBuffer, {1, 3, width, height}, at::kFloat);


    torch::autograd::AutoGradMode guard(false);
    at::AutoNonVariableTypeMode non_var_type_mode(true);
      
      
    float* floatInput = tensor.data_ptr<float>();
    if (!floatInput) {
    return nil;
    }
    NSMutableArray* inputs = [[NSMutableArray alloc] init];
    for (int i = 0; i < 3*width*height; i++) {
    [inputs addObject:@(floatInput[i])];
    }

    auto outputDict = _impl.forward({tensor}).toGenericDict();
      
    // no need for inference - https://pytorch.org/hub/pytorch_vision_deeplabv3_resnet101/ output['out'] contains the semantic masks, and output['aux'] contains the auxillary loss values per-pixel. In inference mode, output['aux'] is not useful.

    auto outputTensor = outputDict.at("out").toTensor();

    float* floatBuffer = outputTensor.data_ptr<float>();
    if (!floatBuffer) {
      return nil;
    }
    NSMutableArray* results = [[NSMutableArray alloc] init];
    for (int i = 0; i < classnum * width * height; i++) {
      [results addObject:@(floatBuffer[i])];
    }
      
      
    unsigned char* buffer = (unsigned char*)malloc(3*width*height);

      
    for (int j=0; j<width; j++) {
      for (int k=0; k<height; k++) {
          int maxj = 0;
          int maxk = 0;
          int maxi = 0;

          float maxnum = -100000.0;
          for (int i=0; i < classnum; i++) {
              if ([results[i*(width*height) + j*width + k] floatValue] > maxnum) {
                  maxnum = [results[i*(width*height) + j*width + k] floatValue];
                  maxj = j; maxk= k; maxi = i;
              }
          }
          
// 21 classes - maxi range is 0-20
//          background
//          aeroplane
//          bicycle
//          bird
//          boat
//          bottle
//          bus
//          car
//          *cat
//          chair
//          cow
//          diningtable
//          dog
//          *horse
//          motorbike
//          *person
//          pottedplant
//          *sheep
//          sofa
//          train
//          tvmonitor
          
          if (maxi==15) {
              buffer[3*(maxj*width + maxk)] = 255;
              buffer[3*(maxj*width + maxk)+1] = 0;
              buffer[3*(maxj*width + maxk)+2] = 0;
          }
              
          else if (maxi==17) {
              buffer[3*(maxj*width + maxk)] = 0;
              buffer[3*(maxj*width + maxk)+1] = 0;
              buffer[3*(maxj*width + maxk)+2] = 255;
          }
          else if (maxi==13) {
              buffer[3*(maxj*width + maxk)] = 0;
              buffer[3*(maxj*width + maxk)+1] = 255;
              buffer[3*(maxj*width + maxk)+2] = 0;
          }
          else if (maxi==8) {
              buffer[3*(maxj*width + maxk)] = 255;
              buffer[3*(maxj*width + maxk)+1] = 0;
              buffer[3*(maxj*width + maxk)+2] = 0;
          }
          else {
              buffer[3*(maxj*width + maxk)] = 0;
              buffer[3*(maxj*width + maxk)+1] = 0;
              buffer[3*(maxj*width + maxk)+2] = 0;
          }
      }
    }
      
      
    UIImage *img = [self convertRGBBufferToUIImage:buffer withWidth:width withHeight:height];
    m_imageView.image = img;

      

    return nil; //[results copy];
    } catch (const std::exception& exception) {
        NSLog(@"%s", exception.what());
    }
    return nil;
}


- (UIImage *) convertRGBBufferToUIImage:(unsigned char *) buffer
                                withWidth:(int) width
                               withHeight:(int) height {
    
    // added code
    char* rgba = (char*)malloc(width*height*4);
    for(int i=0; i < width*height; ++i) {
        rgba[4*i] = buffer[3*i];
        rgba[4*i+1] = buffer[3*i+1];
        rgba[4*i+2] = buffer[3*i+2];
        rgba[4*i+3] = 255;
    }
    //
    
    
    size_t bufferLength = width * height * 4;
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, rgba, bufferLength, NULL);
    size_t bitsPerComponent = 8;
    size_t bitsPerPixel = 32;
    size_t bytesPerRow = 4 * width;
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    if(colorSpaceRef == NULL) {
        NSLog(@"Error allocating color space");
        CGDataProviderRelease(provider);
        return nil;
    }
    
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    CGImageRef iref = CGImageCreate(width,
                                    height,
                                    bitsPerComponent,
                                    bitsPerPixel,
                                    bytesPerRow,
                                    colorSpaceRef,
                                    bitmapInfo,
                                    provider,   // data provider
                                    NULL,       // decode
                                    YES,            // should interpolate
                                    renderingIntent);
    
    uint32_t* pixels = (uint32_t*)malloc(bufferLength);
    
    if(pixels == NULL) {
        NSLog(@"Error: Memory not allocated for bitmap");
        CGDataProviderRelease(provider);
        CGColorSpaceRelease(colorSpaceRef);
        CGImageRelease(iref);
        return nil;
    }
    
    CGContextRef context = CGBitmapContextCreate(pixels,
                                                 width,
                                                 height,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 colorSpaceRef,
                                                 bitmapInfo);
    
    if(context == NULL) {
        NSLog(@"Error context not created");
        free(pixels);
    }
    
    UIImage *image = nil;
    if(context) {
        
        CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, width, height), iref);
        
        CGImageRef imageRef = CGBitmapContextCreateImage(context);
        
        // Support both iPad 3.2 and iPhone 4 Retina displays with the correct scale
        if([UIImage respondsToSelector:@selector(imageWithCGImage:scale:orientation:)]) {
            float scale = [[UIScreen mainScreen] scale];
            image = [UIImage imageWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
        } else {
            image = [UIImage imageWithCGImage:imageRef];
        }
        
        CGImageRelease(imageRef);
        CGContextRelease(context);
    }
    
    CGColorSpaceRelease(colorSpaceRef);
    CGImageRelease(iref);
    CGDataProviderRelease(provider);
    
    if(pixels) {
        free(pixels);
    }
    return image;
}


@end

