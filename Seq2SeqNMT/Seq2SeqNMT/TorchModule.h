#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TorchModule : NSObject

- (nullable instancetype)initWithFileAtPath:(NSString*)filePath
    NS_SWIFT_NAME(init(fileAtPath:))NS_DESIGNATED_INITIALIZER;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@end


@interface NLPTorchModule : TorchModule
- (nullable NSDictionary*)encoderForward:(NSString*)text NS_SWIFT_NAME(encoderForward(text:));
- (nullable NSString*) decoderForward:(NSDictionary*)dict NS_SWIFT_NAME(decoderForward(dict:));
@end

NS_ASSUME_NONNULL_END
