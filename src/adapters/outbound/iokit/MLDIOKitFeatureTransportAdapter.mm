#import "adapters/outbound/iokit/MLDIOKitFeatureTransportAdapter.h"

#import "domain/entities/MLDMouseDevice.h"
#import "domain/value_objects/MLDPerformanceProfile.h"

static NSString *const MLDIOKitFeatureErrorDomain = @"com.mloody.adapters.iokit.feature";

@implementation MLDIOKitFeatureTransportAdapter

- (BOOL)applyPerformanceProfile:(MLDPerformanceProfile *)profile
                       toDevice:(MLDMouseDevice *)device
                          error:(NSError **)error {
    (void)profile;
    (void)device;

    if (error != nil) {
        *error = [NSError errorWithDomain:MLDIOKitFeatureErrorDomain
                                     code:1
                                 userInfo:@{NSLocalizedDescriptionKey : @"Bloody feature-report protocol mapping is not implemented yet."}];
    }

    return NO;
}

@end
