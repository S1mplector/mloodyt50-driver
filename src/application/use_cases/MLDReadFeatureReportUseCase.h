#import <Foundation/Foundation.h>
#include <stdint.h>

#import "application/ports/MLDFeatureTransportPort.h"

@class MLDMouseDevice;

NS_ASSUME_NONNULL_BEGIN

@interface MLDReadFeatureReportUseCase : NSObject

- (instancetype)initWithFeatureTransportPort:(id<MLDFeatureTransportPort>)featureTransportPort NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (nullable NSData *)executeForDevice:(MLDMouseDevice *)device
                             reportID:(uint8_t)reportID
                               length:(NSUInteger)length
                                error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
