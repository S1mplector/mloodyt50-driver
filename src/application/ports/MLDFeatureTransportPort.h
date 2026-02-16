#import <Foundation/Foundation.h>
#include <stdint.h>

@class MLDMouseDevice;
@class MLDPerformanceProfile;

NS_ASSUME_NONNULL_BEGIN

@protocol MLDFeatureTransportPort <NSObject>

- (BOOL)applyPerformanceProfile:(MLDPerformanceProfile *)profile
                       toDevice:(MLDMouseDevice *)device
                          error:(NSError **)error;

- (BOOL)writeFeatureReportWithID:(uint8_t)reportID
                         payload:(NSData *)payload
                        toDevice:(MLDMouseDevice *)device
                           error:(NSError **)error;

- (nullable NSData *)readFeatureReportWithID:(uint8_t)reportID
                                      length:(NSUInteger)length
                                  fromDevice:(MLDMouseDevice *)device
                                       error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
