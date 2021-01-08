// Copyright (c) 2020 Facebook, Inc. and its affiliates.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree.


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface ImageHelper : NSObject

- (UIImage *)createDrawingImageInRect:(CGRect)rect allPoints:(NSArray*)allPoints consecutivePoints:(NSArray*)consecutivePoints;

@end

