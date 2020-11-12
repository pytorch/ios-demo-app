#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface UIImageHelper : NSObject

- (UIImage *) convertRGBBufferToUIImage:(unsigned char *) buffer withWidth:(int)width withHeight:(int)height;
@end

