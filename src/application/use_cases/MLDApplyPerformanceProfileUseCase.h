#import <Foundation/Foundation.h>

#import "application/ports/MLDFeatureTransportPort.h"

@class MLDMouseDevice;
@class MLDPerformanceProfile;

NS_ASSUME_NONNULL_BEGIN

@interface MLDApplyPerformanceProfileUseCase : NSObject

- (instancetype)initWithFeatureTransportPort:(id<MLDFeatureTransportPort>)featureTransportPort NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (BOOL)executeForDevice:(MLDMouseDevice *)device
                 profile:(MLDPerformanceProfile *)profile
                   error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
