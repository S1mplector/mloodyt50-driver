#import "domain/services/MLDProfilePolicy.h"
#import "domain/value_objects/MLDPerformanceProfile.h"

NSString *const MLDProfilePolicyErrorDomain = @"com.mloody.domain.profile-policy";

@implementation MLDProfilePolicy

+ (BOOL)validateProfile:(MLDPerformanceProfile *)profile error:(NSError **)error {
    if (profile.dpi < 100 || profile.dpi > 20000) {
        if (error != nil) {
            *error = [NSError errorWithDomain:MLDProfilePolicyErrorDomain
                                         code:MLDProfilePolicyErrorCodeInvalidDPI
                                     userInfo:@{NSLocalizedDescriptionKey : @"DPI must be between 100 and 20000."}];
        }
        return NO;
    }

    static NSSet<NSNumber *> *validPollingRates;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        validPollingRates = [NSSet setWithArray:@[@125, @250, @500, @1000, @2000, @4000]];
    });

    if (![validPollingRates containsObject:@(profile.pollingRateHz)]) {
        if (error != nil) {
            *error = [NSError errorWithDomain:MLDProfilePolicyErrorDomain
                                         code:MLDProfilePolicyErrorCodeInvalidPollingRate
                                     userInfo:@{NSLocalizedDescriptionKey : @"Polling rate must be one of 125/250/500/1000/2000/4000 Hz."}];
        }
        return NO;
    }

    if (profile.liftOffDistance < 1 || profile.liftOffDistance > 5) {
        if (error != nil) {
            *error = [NSError errorWithDomain:MLDProfilePolicyErrorDomain
                                         code:MLDProfilePolicyErrorCodeInvalidLiftOffDistance
                                     userInfo:@{NSLocalizedDescriptionKey : @"Lift-off distance must be between 1 and 5."}];
        }
        return NO;
    }

    return YES;
}

@end
