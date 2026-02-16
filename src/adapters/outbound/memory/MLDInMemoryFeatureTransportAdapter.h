#import <Foundation/Foundation.h>
#include <stdint.h>

#import "application/ports/MLDFeatureTransportPort.h"

@class MLDMouseDevice;
@class MLDPerformanceProfile;

NS_ASSUME_NONNULL_BEGIN

@interface MLDInMemoryFeatureTransportAdapter : NSObject <MLDFeatureTransportPort>

@property(nonatomic, assign) BOOL shouldFail;
@property(nonatomic, copy) NSString *failureReason;

@property(nonatomic, strong, readonly, nullable) MLDMouseDevice *lastDevice;
@property(nonatomic, strong, readonly, nullable) MLDPerformanceProfile *lastProfile;
@property(nonatomic, copy, readonly) NSDictionary<NSNumber *, NSData *> *writtenReports;

- (void)setMockFeatureReportData:(NSData *)data forReportID:(uint8_t)reportID;

@end

NS_ASSUME_NONNULL_END
