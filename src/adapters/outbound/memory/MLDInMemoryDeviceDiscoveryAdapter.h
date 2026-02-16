#import <Foundation/Foundation.h>

#import "application/ports/MLDDeviceDiscoveryPort.h"

@class MLDMouseDevice;

NS_ASSUME_NONNULL_BEGIN

@interface MLDInMemoryDeviceDiscoveryAdapter : NSObject <MLDDeviceDiscoveryPort>

- (instancetype)initWithDevices:(NSArray<MLDMouseDevice *> *)devices NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
