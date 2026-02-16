#import "application/use_cases/MLDReadFeatureReportUseCase.h"

#import "domain/entities/MLDMouseDevice.h"

@interface MLDReadFeatureReportUseCase ()

@property(nonatomic, strong) id<MLDFeatureTransportPort> featureTransportPort;

@end

@implementation MLDReadFeatureReportUseCase

- (instancetype)initWithFeatureTransportPort:(id<MLDFeatureTransportPort>)featureTransportPort {
    self = [super init];
    if (self == nil) {
        return nil;
    }

    _featureTransportPort = featureTransportPort;
    return self;
}

- (nullable NSData *)executeForDevice:(MLDMouseDevice *)device
                             reportID:(uint8_t)reportID
                               length:(NSUInteger)length
                                error:(NSError **)error {
    return [self.featureTransportPort readFeatureReportWithID:reportID length:length fromDevice:device error:error];
}

@end
