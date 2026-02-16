#import <Foundation/Foundation.h>

#import "adapters/outbound/memory/MLDInMemoryFeatureTransportAdapter.h"
#import "application/use_cases/MLDApplyPerformanceProfileUseCase.h"
#import "domain/entities/MLDMouseDevice.h"
#import "domain/services/MLDProfilePolicy.h"
#import "domain/value_objects/MLDPerformanceProfile.h"

static BOOL Expect(BOOL condition, NSString *message) {
    if (!condition) {
        fprintf(stderr, "Assertion failed: %s\n", message.UTF8String);
        return NO;
    }
    return YES;
}

int main(void) {
    @autoreleasepool {
        MLDInMemoryFeatureTransportAdapter *transport = [[MLDInMemoryFeatureTransportAdapter alloc] init];
        MLDApplyPerformanceProfileUseCase *useCase =
            [[MLDApplyPerformanceProfileUseCase alloc] initWithFeatureTransportPort:transport];

        MLDMouseDevice *device = [[MLDMouseDevice alloc] initWithVendorID:0x09DA
                                                                 productID:0x7B22
                                                                 modelName:@"Bloody W90"
                                                              serialNumber:@"ABC123"];

        MLDPerformanceProfile *validProfile = [[MLDPerformanceProfile alloc] initWithDPI:1600
                                                                            pollingRateHz:1000
                                                                          liftOffDistance:2];

        NSError *applyError = nil;
        BOOL applied = [useCase executeForDevice:device profile:validProfile error:&applyError];
        if (!Expect(applied, @"Expected valid profile to be applied.")) {
            return 1;
        }
        if (!Expect(applyError == nil, @"Expected no error when applying a valid profile.")) {
            return 1;
        }
        if (!Expect(transport.lastProfile != nil, @"Expected transport to record last profile.")) {
            return 1;
        }
        if (!Expect(transport.lastProfile.dpi == 1600, @"Expected recorded profile DPI to match input.")) {
            return 1;
        }

        MLDPerformanceProfile *invalidProfile = [[MLDPerformanceProfile alloc] initWithDPI:50
                                                                              pollingRateHz:1000
                                                                            liftOffDistance:2];
        NSError *validationError = nil;
        BOOL invalidApplied = [useCase executeForDevice:device profile:invalidProfile error:&validationError];
        if (!Expect(!invalidApplied, @"Expected invalid profile to be rejected.")) {
            return 1;
        }
        if (!Expect(validationError != nil, @"Expected validation error for invalid profile.")) {
            return 1;
        }
        if (!Expect([validationError.domain isEqualToString:MLDProfilePolicyErrorDomain],
                    @"Expected profile-policy error domain for invalid profile.")) {
            return 1;
        }

        transport.shouldFail = YES;
        transport.failureReason = @"Simulated transport write failure.";

        NSError *transportError = nil;
        BOOL transportApplied = [useCase executeForDevice:device profile:validProfile error:&transportError];
        if (!Expect(!transportApplied, @"Expected transport failure to bubble up.")) {
            return 1;
        }
        if (!Expect(transportError != nil, @"Expected error from transport failure.")) {
            return 1;
        }
    }

    return 0;
}
