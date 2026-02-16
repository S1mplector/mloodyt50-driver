#import "adapters/outbound/iokit/MLDIOKitDeviceDiscoveryAdapter.h"

#import <IOKit/hid/IOHIDKeys.h>
#import <IOKit/hid/IOHIDLib.h>
#import <IOKit/hid/IOHIDUsageTables.h>

#import "domain/entities/MLDMouseDevice.h"

static NSString *const MLDIOKitDiscoveryErrorDomain = @"com.mloody.adapters.iokit.discovery";

@implementation MLDIOKitDeviceDiscoveryAdapter

- (NSArray<MLDMouseDevice *> *)discoverConnectedDevices:(NSError **)error {
    IOHIDManagerRef manager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
    if (manager == NULL) {
        if (error != nil) {
            *error = [NSError errorWithDomain:MLDIOKitDiscoveryErrorDomain
                                         code:1
                                     userInfo:@{NSLocalizedDescriptionKey : @"Failed to create IOHID manager."}];
        }
        return @[];
    }

    NSDictionary *matching = @{
        @kIOHIDDeviceUsagePageKey : @(kHIDPage_GenericDesktop),
        @kIOHIDDeviceUsageKey : @(kHIDUsage_GD_Mouse)
    };

    IOHIDManagerSetDeviceMatching(manager, (__bridge CFDictionaryRef)matching);

    IOReturn openStatus = IOHIDManagerOpen(manager, kIOHIDOptionsTypeNone);
    if (openStatus != kIOReturnSuccess) {
        if (error != nil) {
            *error = [NSError errorWithDomain:MLDIOKitDiscoveryErrorDomain
                                         code:openStatus
                                     userInfo:@{NSLocalizedDescriptionKey : @"Failed to open IOHID manager."}];
        }
        CFRelease(manager);
        return @[];
    }

    CFSetRef devicesRef = IOHIDManagerCopyDevices(manager);
    NSArray *rawDevices = @[];
    if (devicesRef != NULL) {
        rawDevices = [(__bridge NSSet *)devicesRef allObjects];
        CFRelease(devicesRef);
    }

    NSMutableArray<MLDMouseDevice *> *devices = [NSMutableArray array];
    for (id object in rawDevices) {
        IOHIDDeviceRef deviceRef = (__bridge IOHIDDeviceRef)object;

        NSNumber *vendorNumber = (__bridge NSNumber *)IOHIDDeviceGetProperty(deviceRef, CFSTR(kIOHIDVendorIDKey));
        NSNumber *productNumber = (__bridge NSNumber *)IOHIDDeviceGetProperty(deviceRef, CFSTR(kIOHIDProductIDKey));

        if (vendorNumber == nil || productNumber == nil) {
            continue;
        }

        NSString *productName = (__bridge NSString *)IOHIDDeviceGetProperty(deviceRef, CFSTR(kIOHIDProductKey));
        NSString *serial = (__bridge NSString *)IOHIDDeviceGetProperty(deviceRef, CFSTR(kIOHIDSerialNumberKey));

        if (productName.length == 0) {
            productName = @"Unknown Mouse";
        }
        if (serial == nil) {
            serial = @"";
        }

        MLDMouseDevice *device = [[MLDMouseDevice alloc] initWithVendorID:(uint16_t)vendorNumber.unsignedShortValue
                                                                 productID:(uint16_t)productNumber.unsignedShortValue
                                                                 modelName:productName
                                                              serialNumber:serial];
        [devices addObject:device];
    }

    IOHIDManagerClose(manager, kIOHIDOptionsTypeNone);
    CFRelease(manager);

    return [devices copy];
}

@end
