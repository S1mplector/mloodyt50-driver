#import "adapters/outbound/memory/MLDInMemoryDeviceDiscoveryAdapter.h"

#import "domain/entities/MLDMouseDevice.h"

@interface MLDInMemoryDeviceDiscoveryAdapter ()

@property(nonatomic, copy) NSArray<MLDMouseDevice *> *devices;

@end

@implementation MLDInMemoryDeviceDiscoveryAdapter

- (instancetype)initWithDevices:(NSArray<MLDMouseDevice *> *)devices {
    self = [super init];
    if (self == nil) {
        return nil;
    }

    _devices = [devices copy];
    return self;
}

- (NSArray<MLDMouseDevice *> *)discoverConnectedDevices:(NSError **)error {
    (void)error;
    return [self.devices copy];
}

@end
