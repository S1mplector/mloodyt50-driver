#import <Foundation/Foundation.h>

@class MLDMouseDevice;

NS_ASSUME_NONNULL_BEGIN

@interface MLDSupportedDeviceCatalog : NSObject

+ (BOOL)isSupportedDevice:(MLDMouseDevice *)device;
+ (BOOL)isBloodyVendorDevice:(MLDMouseDevice *)device;
+ (BOOL)isT50Device:(MLDMouseDevice *)device;
+ (NSSet<NSNumber *> *)supportedVendorIDs;

@end

NS_ASSUME_NONNULL_END
