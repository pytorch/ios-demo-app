// Copyright (c) 2020 Facebook, Inc. and its affiliates.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree.


#import <UIKit/UIKit.h>
#import "ImageHelper.h"

@implementation ImageHelper : NSObject


- (UIImage *)createDrawingImageInRect:(CGRect)rect allPoints:(NSArray*)allPoints consecutivePoints:(NSArray*)consecutivePoints
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(rect.size.width, rect.size.height), NO, 0.0);
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    for (NSArray *cp in allPoints) {
        bool firstPoint = TRUE;
        for (NSValue *pointVal in cp) {
            CGPoint point = pointVal.CGPointValue;
            if (firstPoint) {
                [path moveToPoint:point];
                firstPoint = FALSE;
            }
            else
                [path addLineToPoint:point];
        }
    }
    
    bool firstPoint = TRUE;
    for (NSValue *pointVal in consecutivePoints) {
        CGPoint point = pointVal.CGPointValue;
        if (firstPoint) {
            [path moveToPoint:point];
            firstPoint = FALSE;
        }
        else
            [path addLineToPoint:point];
    }
    
    path.lineWidth = 6.0;
    [[UIColor blackColor] setStroke];
    [path stroke];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}



@end
