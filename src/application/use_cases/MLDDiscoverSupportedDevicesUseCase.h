#import <Foundation/Foundation.h>

#import "application/ports/MLDDeviceDiscoveryPort.h"

@class MLDMouseDevice;

NS_ASSUME_NONNULL_BEGIN

@interface MLDDiscoverSupportedDevicesUseCase : NSObject

- (instancetype)initWithDiscoveryPort:(id<MLDDeviceDiscoveryPort>)discoveryPort NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (NSArray<MLDMouseDevice *> *)execute:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
