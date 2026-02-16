#import "application/use_cases/MLDWriteFeatureReportUseCase.h"

#import "domain/entities/MLDMouseDevice.h"

@interface MLDWriteFeatureReportUseCase ()

@property(nonatomic, strong) id<MLDFeatureTransportPort> featureTransportPort;

@end

@implementation MLDWriteFeatureReportUseCase

- (instancetype)initWithFeatureTransportPort:(id<MLDFeatureTransportPort>)featureTransportPort {
    self = [super init];
    if (self == nil) {
        return nil;
    }

    _featureTransportPort = featureTransportPort;
    return self;
}

- (BOOL)executeForDevice:(MLDMouseDevice *)device
                reportID:(uint8_t)reportID
                 payload:(NSData *)payload
                   error:(NSError **)error {
    return [self.featureTransportPort writeFeatureReportWithID:reportID payload:payload toDevice:device error:error];
}

@end
