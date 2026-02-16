#import "adapters/outbound/iokit/MLDIOKitFeatureTransportAdapter.h"

#import <IOKit/hid/IOHIDKeys.h>
#import <IOKit/hid/IOHIDLib.h>

#import "domain/entities/MLDMouseDevice.h"
#import "domain/value_objects/MLDPerformanceProfile.h"

static NSString *const MLDIOKitFeatureErrorDomain = @"com.mloody.adapters.iokit.feature";

typedef NS_ENUM(NSInteger, MLDIOKitFeatureErrorCode) {
    MLDIOKitFeatureErrorCodeCreateManagerFailed = 1,
    MLDIOKitFeatureErrorCodeOpenManagerFailed = 2,
    MLDIOKitFeatureErrorCodeDeviceNotFound = 3,
    MLDIOKitFeatureErrorCodeOpenDeviceFailed = 4,
    MLDIOKitFeatureErrorCodeWriteFailed = 5,
    MLDIOKitFeatureErrorCodeReadFailed = 6,
    MLDIOKitFeatureErrorCodeProfileMappingNotImplemented = 7,
    MLDIOKitFeatureErrorCodeInvalidReadLength = 8,
};

static NSError *MLDMakeFeatureError(MLDIOKitFeatureErrorCode code, NSString *description, IOReturn status) {
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey];
    if (status != kIOReturnSuccess) {
        userInfo[@"io_return"] = @(status);
    }

    return [NSError errorWithDomain:MLDIOKitFeatureErrorDomain code:code userInfo:userInfo];
}

static BOOL MLDMatchesTargetDevice(IOHIDDeviceRef deviceRef, MLDMouseDevice *target) {
    NSNumber *vendor = (__bridge NSNumber *)IOHIDDeviceGetProperty(deviceRef, CFSTR(kIOHIDVendorIDKey));
    NSNumber *product = (__bridge NSNumber *)IOHIDDeviceGetProperty(deviceRef, CFSTR(kIOHIDProductIDKey));
    if (vendor == nil || product == nil) {
        return NO;
    }

    if ((uint16_t)vendor.unsignedShortValue != target.vendorID ||
        (uint16_t)product.unsignedShortValue != target.productID) {
        return NO;
    }

    if (target.locationID != 0) {
        NSNumber *location = (__bridge NSNumber *)IOHIDDeviceGetProperty(deviceRef, CFSTR(kIOHIDLocationIDKey));
        return location != nil && location.unsignedIntValue == target.locationID;
    }

    if (target.serialNumber.length > 0) {
        NSString *serial = (__bridge NSString *)IOHIDDeviceGetProperty(deviceRef, CFSTR(kIOHIDSerialNumberKey));
        return serial != nil && [serial isEqualToString:target.serialNumber];
    }

    if (target.modelName.length > 0) {
        NSString *model = (__bridge NSString *)IOHIDDeviceGetProperty(deviceRef, CFSTR(kIOHIDProductKey));
        return model != nil && [model isEqualToString:target.modelName];
    }

    return YES;
}

static NSUInteger MLDFeatureTransportScore(IOHIDDeviceRef deviceRef) {
    NSNumber *featureSize = (__bridge NSNumber *)IOHIDDeviceGetProperty(deviceRef, CFSTR(kIOHIDMaxFeatureReportSizeKey));
    NSNumber *outputSize = (__bridge NSNumber *)IOHIDDeviceGetProperty(deviceRef, CFSTR(kIOHIDMaxOutputReportSizeKey));
    NSNumber *inputSize = (__bridge NSNumber *)IOHIDDeviceGetProperty(deviceRef, CFSTR(kIOHIDMaxInputReportSizeKey));

    // Prefer interfaces that actually expose feature reports, then larger output/input capacity.
    NSUInteger score = 0;
    if (featureSize != nil) {
        score += (featureSize.unsignedIntegerValue << 16);
    }
    if (outputSize != nil) {
        score += (outputSize.unsignedIntegerValue << 8);
    }
    if (inputSize != nil) {
        score += inputSize.unsignedIntegerValue;
    }
    return score;
}

@interface MLDIOKitFeatureTransportAdapter ()

- (nullable IOHIDDeviceRef)copyDeviceRefForDevice:(MLDMouseDevice *)device error:(NSError **)error;

@end

@implementation MLDIOKitFeatureTransportAdapter

- (nullable IOHIDDeviceRef)copyDeviceRefForDevice:(MLDMouseDevice *)device error:(NSError **)error {
    IOHIDManagerRef manager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
    if (manager == NULL) {
        if (error != nil) {
            *error = MLDMakeFeatureError(MLDIOKitFeatureErrorCodeCreateManagerFailed,
                                         @"Failed to create IOHID manager.",
                                         kIOReturnError);
        }
        return NULL;
    }

    NSDictionary *matching = @{
        @kIOHIDVendorIDKey : @(device.vendorID),
        @kIOHIDProductIDKey : @(device.productID)
    };
    IOHIDManagerSetDeviceMatching(manager, (__bridge CFDictionaryRef)matching);

    IOReturn managerOpenStatus = IOHIDManagerOpen(manager, kIOHIDOptionsTypeNone);
    if (managerOpenStatus != kIOReturnSuccess) {
        if (error != nil) {
            *error = MLDMakeFeatureError(MLDIOKitFeatureErrorCodeOpenManagerFailed,
                                         @"Failed to open IOHID manager.",
                                         managerOpenStatus);
        }
        CFRelease(manager);
        return NULL;
    }

    IOHIDDeviceRef selected = NULL;
    NSUInteger selectedScore = 0;
    CFSetRef devicesRef = IOHIDManagerCopyDevices(manager);
    if (devicesRef != NULL) {
        NSArray *allDevices = [(__bridge NSSet *)devicesRef allObjects];
        for (id object in allDevices) {
            IOHIDDeviceRef candidate = (__bridge IOHIDDeviceRef)object;
            if (MLDMatchesTargetDevice(candidate, device)) {
                NSUInteger score = MLDFeatureTransportScore(candidate);
                if (selected == NULL || score > selectedScore) {
                    if (selected != NULL) {
                        CFRelease(selected);
                    }
                    selected = candidate;
                    selectedScore = score;
                    CFRetain(selected);
                }
            }
        }
        CFRelease(devicesRef);
    }

    IOHIDManagerClose(manager, kIOHIDOptionsTypeNone);
    CFRelease(manager);

    if (selected == NULL && error != nil) {
        NSString *message = [NSString stringWithFormat:@"No matching HID device for vendor=0x%04x product=0x%04x.",
                                                       device.vendorID,
                                                       device.productID];
        *error = MLDMakeFeatureError(MLDIOKitFeatureErrorCodeDeviceNotFound, message, kIOReturnNotFound);
    }

    return selected;
}

- (BOOL)applyPerformanceProfile:(MLDPerformanceProfile *)profile
                       toDevice:(MLDMouseDevice *)device
                          error:(NSError **)error {
    (void)profile;
    (void)device;

    if (error != nil) {
        *error = MLDMakeFeatureError(MLDIOKitFeatureErrorCodeProfileMappingNotImplemented,
                                     @"T50 profile packet mapping is not implemented yet. Use feature-set/feature-get for direct control.",
                                     kIOReturnUnsupported);
    }
    return NO;
}

- (BOOL)writeFeatureReportWithID:(uint8_t)reportID
                         payload:(NSData *)payload
                        toDevice:(MLDMouseDevice *)device
                           error:(NSError **)error {
    NSError *deviceError = nil;
    IOHIDDeviceRef deviceRef = [self copyDeviceRefForDevice:device error:&deviceError];
    if (deviceRef == NULL) {
        if (error != nil) {
            *error = deviceError;
        }
        return NO;
    }

    IOReturn openStatus = IOHIDDeviceOpen(deviceRef, kIOHIDOptionsTypeNone);
    if (openStatus != kIOReturnSuccess) {
        if (error != nil) {
            *error = MLDMakeFeatureError(MLDIOKitFeatureErrorCodeOpenDeviceFailed,
                                         @"Failed to open HID device.",
                                         openStatus);
        }
        CFRelease(deviceRef);
        return NO;
    }

    const uint8_t *bytes = (const uint8_t *)payload.bytes;
    IOReturn writeStatus = IOHIDDeviceSetReport(deviceRef,
                                                kIOHIDReportTypeFeature,
                                                reportID,
                                                bytes,
                                                (CFIndex)payload.length);

    IOHIDDeviceClose(deviceRef, kIOHIDOptionsTypeNone);
    CFRelease(deviceRef);

    if (writeStatus != kIOReturnSuccess) {
        if (error != nil) {
            NSString *message = [NSString stringWithFormat:@"Failed to write feature report 0x%02x.", reportID];
            *error = MLDMakeFeatureError(MLDIOKitFeatureErrorCodeWriteFailed, message, writeStatus);
        }
        return NO;
    }

    return YES;
}

- (nullable NSData *)readFeatureReportWithID:(uint8_t)reportID
                                      length:(NSUInteger)length
                                  fromDevice:(MLDMouseDevice *)device
                                       error:(NSError **)error {
    if (length == 0) {
        if (error != nil) {
            *error = MLDMakeFeatureError(MLDIOKitFeatureErrorCodeInvalidReadLength,
                                         @"Feature report read length must be greater than zero.",
                                         kIOReturnBadArgument);
        }
        return nil;
    }

    NSError *deviceError = nil;
    IOHIDDeviceRef deviceRef = [self copyDeviceRefForDevice:device error:&deviceError];
    if (deviceRef == NULL) {
        if (error != nil) {
            *error = deviceError;
        }
        return nil;
    }

    IOReturn openStatus = IOHIDDeviceOpen(deviceRef, kIOHIDOptionsTypeNone);
    if (openStatus != kIOReturnSuccess) {
        if (error != nil) {
            *error = MLDMakeFeatureError(MLDIOKitFeatureErrorCodeOpenDeviceFailed,
                                         @"Failed to open HID device.",
                                         openStatus);
        }
        CFRelease(deviceRef);
        return nil;
    }

    NSMutableData *data = [NSMutableData dataWithLength:length];
    CFIndex reportLength = (CFIndex)length;
    IOReturn readStatus = IOHIDDeviceGetReport(deviceRef,
                                               kIOHIDReportTypeFeature,
                                               reportID,
                                               (uint8_t *)data.mutableBytes,
                                               &reportLength);

    IOHIDDeviceClose(deviceRef, kIOHIDOptionsTypeNone);
    CFRelease(deviceRef);

    if (readStatus != kIOReturnSuccess) {
        if (error != nil) {
            NSString *message = [NSString stringWithFormat:@"Failed to read feature report 0x%02x.", reportID];
            *error = MLDMakeFeatureError(MLDIOKitFeatureErrorCodeReadFailed, message, readStatus);
        }
        return nil;
    }

    [data setLength:(NSUInteger)reportLength];
    return [data copy];
}

@end
