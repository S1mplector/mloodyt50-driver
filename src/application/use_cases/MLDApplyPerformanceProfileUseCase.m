#import "application/use_cases/MLDApplyPerformanceProfileUseCase.h"

#import "domain/entities/MLDMouseDevice.h"
#import "domain/services/MLDProfilePolicy.h"
#import "domain/value_objects/MLDPerformanceProfile.h"

@interface MLDApplyPerformanceProfileUseCase ()

@property(nonatomic, strong) id<MLDFeatureTransportPort> featureTransportPort;

@end

@implementation MLDApplyPerformanceProfileUseCase

- (instancetype)initWithFeatureTransportPort:(id<MLDFeatureTransportPort>)featureTransportPort {
    self = [super init];
    if (self == nil) {
        return nil;
    }

    _featureTransportPort = featureTransportPort;
    return self;
}

- (BOOL)executeForDevice:(MLDMouseDevice *)device
                 profile:(MLDPerformanceProfile *)profile
                   error:(NSError **)error {
    if (![MLDProfilePolicy validateProfile:profile error:error]) {
        return NO;
    }

    return [self.featureTransportPort applyPerformanceProfile:profile toDevice:device error:error];
}

@end
