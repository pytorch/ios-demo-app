#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TorchModule : NSObject

- (nullable instancetype)initWithFileAtPath:(NSString*)filePath
    NS_SWIFT_NAME(init(fileAtPath:))NS_DESIGNATED_INITIALIZER;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@end

@interface VisionTorchModule : TorchModule
- (nullable NSArray<NSNumber*>*)predictImage:(void*)imageBuffer NS_SWIFT_NAME(predict(image:));
@end

@interface NLPTorchModule : TorchModule
- (nullable NSArray<NSString*>*)topics;
- (nullable NSArray<NSNumber*>*)predictText:(NSString*)text NS_SWIFT_NAME(predict(text:));
@end

NS_ASSUME_NONNULL_END
