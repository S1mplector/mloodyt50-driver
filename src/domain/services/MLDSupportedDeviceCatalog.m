#import "domain/services/MLDSupportedDeviceCatalog.h"
#import "domain/entities/MLDMouseDevice.h"

@implementation MLDSupportedDeviceCatalog

+ (BOOL)isSupportedDevice:(MLDMouseDevice *)device {
    return [[self supportedVendorIDs] containsObject:@(device.vendorID)];
}

+ (NSSet<NSNumber *> *)supportedVendorIDs {
    static NSSet<NSNumber *> *vendorIDs;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 0x09DA is commonly used by A4Tech/Bloody devices.
        vendorIDs = [NSSet setWithArray:@[@0x09DA]];
    });
    return vendorIDs;
}

@end
