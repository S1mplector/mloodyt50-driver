#import "adapters/outbound/memory/MLDInMemoryFeatureTransportAdapter.h"

#import "domain/entities/MLDMouseDevice.h"
#import "domain/value_objects/MLDPerformanceProfile.h"

static NSString *const MLDInMemoryFeatureErrorDomain = @"com.mloody.adapters.memory.feature";

@interface MLDInMemoryFeatureTransportAdapter ()

@property(nonatomic, strong, readwrite, nullable) MLDMouseDevice *lastDevice;
@property(nonatomic, strong, readwrite, nullable) MLDPerformanceProfile *lastProfile;

@end

@implementation MLDInMemoryFeatureTransportAdapter

- (instancetype)init {
    self = [super init];
    if (self == nil) {
        return nil;
    }

    _shouldFail = NO;
    _failureReason = @"Forced in-memory adapter failure.";
    return self;
}

- (BOOL)applyPerformanceProfile:(MLDPerformanceProfile *)profile
                       toDevice:(MLDMouseDevice *)device
                          error:(NSError **)error {
    if (self.shouldFail) {
        if (error != nil) {
            *error = [NSError errorWithDomain:MLDInMemoryFeatureErrorDomain
                                         code:1
                                     userInfo:@{NSLocalizedDescriptionKey : self.failureReason}];
        }
        return NO;
    }

    self.lastDevice = device;
    self.lastProfile = profile;
    return YES;
}

@end
