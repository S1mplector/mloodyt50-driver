#import <Foundation/Foundation.h>

#import "application/ports/MLDFeatureTransportPort.h"

@class MLDMouseDevice;
@class MLDPerformanceProfile;

NS_ASSUME_NONNULL_BEGIN

@interface MLDInMemoryFeatureTransportAdapter : NSObject <MLDFeatureTransportPort>

@property(nonatomic, assign) BOOL shouldFail;
@property(nonatomic, copy) NSString *failureReason;

@property(nonatomic, strong, readonly, nullable) MLDMouseDevice *lastDevice;
@property(nonatomic, strong, readonly, nullable) MLDPerformanceProfile *lastProfile;

@end

NS_ASSUME_NONNULL_END
