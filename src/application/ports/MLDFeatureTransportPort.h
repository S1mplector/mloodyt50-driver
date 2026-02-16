#import <Foundation/Foundation.h>

@class MLDMouseDevice;
@class MLDPerformanceProfile;

NS_ASSUME_NONNULL_BEGIN

@protocol MLDFeatureTransportPort <NSObject>

- (BOOL)applyPerformanceProfile:(MLDPerformanceProfile *)profile
                       toDevice:(MLDMouseDevice *)device
                          error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
