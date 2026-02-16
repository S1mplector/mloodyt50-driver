#import <Foundation/Foundation.h>

@class MLDMouseDevice;

NS_ASSUME_NONNULL_BEGIN

@protocol MLDDeviceDiscoveryPort <NSObject>

- (NSArray<MLDMouseDevice *> *)discoverConnectedDevices:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
