#import <Foundation/Foundation.h>

#import "domain/entities/MLDMouseDevice.h"
#import "domain/services/MLDSupportedDeviceCatalog.h"

static BOOL Expect(BOOL condition, NSString *message) {
    if (!condition) {
        fprintf(stderr, "Assertion failed: %s\n", message.UTF8String);
        return NO;
    }
    return YES;
}

int main(void) {
    @autoreleasepool {
        MLDMouseDevice *t50 = [[MLDMouseDevice alloc] initWithVendorID:0x09DA
                                                              productID:0x1001
                                                              modelName:@"Bloody T50"
                                                           serialNumber:@"T50-001"];
        MLDMouseDevice *otherBloody = [[MLDMouseDevice alloc] initWithVendorID:0x09DA
                                                                      productID:0x1002
                                                                      modelName:@"Bloody V8"
                                                                   serialNumber:@"V8-001"];
        MLDMouseDevice *pidMatchedT50 = [[MLDMouseDevice alloc] initWithVendorID:0x09DA
                                                                        productID:0x7F8D
                                                                        modelName:@"USB Device"
                                                                     serialNumber:@"PID-T50"];
        MLDMouseDevice *otherVendor = [[MLDMouseDevice alloc] initWithVendorID:0x046D
                                                                      productID:0xC077
                                                                      modelName:@"Logitech Mouse"
                                                                   serialNumber:@"L-001"];

        if (!Expect([MLDSupportedDeviceCatalog isSupportedDevice:t50], @"Expected T50 to be supported.")) {
            return 1;
        }
        if (!Expect([MLDSupportedDeviceCatalog isSupportedDevice:otherBloody], @"Expected Bloody vendor devices to be supported.")) {
            return 1;
        }
        if (!Expect(![MLDSupportedDeviceCatalog isSupportedDevice:otherVendor], @"Expected non-Bloody vendor to be unsupported.")) {
            return 1;
        }

        if (!Expect([MLDSupportedDeviceCatalog isT50Device:t50], @"Expected model name T50 to be detected.")) {
            return 1;
        }
        if (!Expect([MLDSupportedDeviceCatalog isT50Device:pidMatchedT50], @"Expected known T50 product ID to be detected.")) {
            return 1;
        }
        if (!Expect(![MLDSupportedDeviceCatalog isT50Device:otherBloody], @"Expected non-T50 Bloody model to not match T50.")) {
            return 1;
        }
        if (!Expect(![MLDSupportedDeviceCatalog isT50Device:otherVendor], @"Expected non-Bloody devices to fail T50 match.")) {
            return 1;
        }
    }

    return 0;
}
