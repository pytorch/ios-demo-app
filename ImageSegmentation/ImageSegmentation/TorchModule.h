// Copyright (c) 2020 Facebook, Inc. and its affiliates.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree.



#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TorchModule : NSObject

- (nullable instancetype)initWithFileAtPath:(NSString*)filePath
    NS_SWIFT_NAME(init(fileAtPath:))NS_DESIGNATED_INITIALIZER;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (unsigned char*)segmentImage:(void*)imageBuffer withWidth:(int)width withHeight:(int)height NS_SWIFT_NAME(segment(image:withWidth:withHeight:));


@end

NS_ASSUME_NONNULL_END
