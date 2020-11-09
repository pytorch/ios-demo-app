#import <UIKit/UIKit.h>

@implementation UIImageHelper : NSObject


- (UIImage*)convertRGBBufferToUIImage:(unsigned char*)buffer
                            withWidth:(int)width
                           withHeight:(int)height {
    char* rgba = (char*)malloc(width * height * 4);
    for (int i = 0; i < width * height; ++i) {
        rgba[4 * i] = buffer[3 * i];
        rgba[4 * i + 1] = buffer[3 * i + 1];
        rgba[4 * i + 2] = buffer[3 * i + 2];
        rgba[4 * i + 3] = 255;
    }

    size_t bufferLength = width * height * 4;
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, rgba, bufferLength, NULL);
    size_t bitsPerComponent = 8;
    size_t bitsPerPixel = 32;
    size_t bytesPerRow = 4 * width;

    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    if (colorSpaceRef == NULL) {
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
        provider,
        NULL,
        YES,
        renderingIntent);

    uint32_t* pixels = (uint32_t*)malloc(bufferLength);

    if (pixels == NULL) {
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

    if (context == NULL) {
        NSLog(@"Error context not created");
        free(pixels);
    }

    UIImage* image = nil;
    if (context) {
        CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, width, height), iref);
        CGImageRef imageRef = CGBitmapContextCreateImage(context);
        if ([UIImage respondsToSelector:@selector(imageWithCGImage:scale:orientation:)]) {
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

    if (pixels) {
        free(pixels);
    }
    return image;
}

@end
