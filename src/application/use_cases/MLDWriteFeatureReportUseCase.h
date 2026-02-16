#import <Foundation/Foundation.h>
#include <stdint.h>

#import "application/ports/MLDFeatureTransportPort.h"

@class MLDMouseDevice;

NS_ASSUME_NONNULL_BEGIN

@interface MLDWriteFeatureReportUseCase : NSObject

- (instancetype)initWithFeatureTransportPort:(id<MLDFeatureTransportPort>)featureTransportPort NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (BOOL)executeForDevice:(MLDMouseDevice *)device
                reportID:(uint8_t)reportID
                 payload:(NSData *)payload
                   error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
