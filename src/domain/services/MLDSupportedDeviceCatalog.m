#import "domain/services/MLDSupportedDeviceCatalog.h"
#import "domain/entities/MLDMouseDevice.h"

@interface MLDSupportedDeviceCatalog ()

+ (NSSet<NSNumber *> *)knownT50ProductIDs;

@end

@implementation MLDSupportedDeviceCatalog

+ (BOOL)isSupportedDevice:(MLDMouseDevice *)device {
    return [self isBloodyVendorDevice:device];
}

+ (BOOL)isBloodyVendorDevice:(MLDMouseDevice *)device {
    return [[self supportedVendorIDs] containsObject:@(device.vendorID)];
}

+ (BOOL)isT50Device:(MLDMouseDevice *)device {
    if (![self isBloodyVendorDevice:device]) {
        return NO;
    }

    if ([[self knownT50ProductIDs] containsObject:@(device.productID)]) {
        return YES;
    }

    NSString *normalizedModel = device.modelName.uppercaseString;
    return [normalizedModel containsString:@"T50"];
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

+ (NSSet<NSNumber *> *)knownT50ProductIDs {
    static NSSet<NSNumber *> *productIDs;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Derived from real-device probe output in this repository flow.
        productIDs = [NSSet setWithArray:@[@0x7F8D]];
    });
    return productIDs;
}

@end
