#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^ChoySeeUpdateCompletion)(NSString * _Nullable tag,
	NSURL * _Nullable newerReleaseURL, NSString * _Nullable failureMessage);

@interface ChoySeeUpdateChecker : NSObject
// Called from the Updates button. Completion runs on the main thread.
+ (void)checkInstalledVersion:(nullable NSString *)version completion:(ChoySeeUpdateCompletion)completion;
@end

NS_ASSUME_NONNULL_END
