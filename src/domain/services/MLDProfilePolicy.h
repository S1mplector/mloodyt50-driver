#import <Foundation/Foundation.h>

@class MLDPerformanceProfile;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const MLDProfilePolicyErrorDomain;

typedef NS_ERROR_ENUM(MLDProfilePolicyErrorDomain, MLDProfilePolicyErrorCode) {
    MLDProfilePolicyErrorCodeInvalidDPI = 1,
    MLDProfilePolicyErrorCodeInvalidPollingRate = 2,
    MLDProfilePolicyErrorCodeInvalidLiftOffDistance = 3,
};

@interface MLDProfilePolicy : NSObject

+ (BOOL)validateProfile:(MLDPerformanceProfile *)profile error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
