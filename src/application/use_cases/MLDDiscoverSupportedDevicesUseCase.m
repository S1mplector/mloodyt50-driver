#import "application/use_cases/MLDDiscoverSupportedDevicesUseCase.h"

#import "domain/entities/MLDMouseDevice.h"
#import "domain/services/MLDSupportedDeviceCatalog.h"

@interface MLDDiscoverSupportedDevicesUseCase ()

@property(nonatomic, strong) id<MLDDeviceDiscoveryPort> discoveryPort;

@end

@implementation MLDDiscoverSupportedDevicesUseCase

- (instancetype)initWithDiscoveryPort:(id<MLDDeviceDiscoveryPort>)discoveryPort {
    self = [super init];
    if (self == nil) {
        return nil;
    }

    _discoveryPort = discoveryPort;
    return self;
}

- (NSArray<MLDMouseDevice *> *)execute:(NSError **)error {
    NSArray<MLDMouseDevice *> *devices = [self.discoveryPort discoverConnectedDevices:error];
    if (devices == nil) {
        return @[];
    }

    NSMutableArray<MLDMouseDevice *> *supported = [NSMutableArray array];
    for (MLDMouseDevice *device in devices) {
        if ([MLDSupportedDeviceCatalog isSupportedDevice:device]) {
            [supported addObject:device];
        }
    }

    return [supported copy];
}

@end
