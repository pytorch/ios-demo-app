#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TorchModule : NSObject

- (nullable instancetype)initWithFileAtPath:(NSString*)filePath width:(long)width height:(long)height
NS_SWIFT_NAME(init(fileAtPath:width:height:))NS_DESIGNATED_INITIALIZER;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (nullable float*)predictImage:(void*)imageBuffer NS_SWIFT_NAME(predict(image:));

@end

NS_ASSUME_NONNULL_END
