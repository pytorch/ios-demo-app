#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TorchModule : NSObject

+ (nullable instancetype)loadModel:(NSString*)modelPath;

@end

@interface VisionTorchModule : TorchModule
- (nullable NSArray<NSNumber*>*)predictImage:(void*)imageBuffer;
@end

@interface NLPTorchModule : TorchModule
- (NSArray<NSString*>*)topics;
- (nullable NSArray<NSNumber*>*)predictText:(NSString*)text;
@end

NS_ASSUME_NONNULL_END
