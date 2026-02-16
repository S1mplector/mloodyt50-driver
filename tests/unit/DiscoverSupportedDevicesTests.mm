#import <Foundation/Foundation.h>

#import "adapters/outbound/memory/MLDInMemoryDeviceDiscoveryAdapter.h"
#import "application/use_cases/MLDDiscoverSupportedDevicesUseCase.h"
#import "domain/entities/MLDMouseDevice.h"

static BOOL Expect(BOOL condition, NSString *message) {
    if (!condition) {
        fprintf(stderr, "Assertion failed: %s\n", message.UTF8String);
        return NO;
    }
    return YES;
}

int main(void) {
    @autoreleasepool {
        MLDMouseDevice *supported = [[MLDMouseDevice alloc] initWithVendorID:0x09DA
                                                                    productID:0x7B22
                                                                    modelName:@"Bloody W90"
                                                                 serialNumber:@"ABC123"];
        MLDMouseDevice *unsupported = [[MLDMouseDevice alloc] initWithVendorID:0x046D
                                                                      productID:0xC52B
                                                                      modelName:@"Other Mouse"
                                                                   serialNumber:@"XYZ987"];

        MLDInMemoryDeviceDiscoveryAdapter *discovery =
            [[MLDInMemoryDeviceDiscoveryAdapter alloc] initWithDevices:@[supported, unsupported]];

        MLDDiscoverSupportedDevicesUseCase *useCase =
            [[MLDDiscoverSupportedDevicesUseCase alloc] initWithDiscoveryPort:discovery];

        NSError *error = nil;
        NSArray<MLDMouseDevice *> *result = [useCase execute:&error];

        if (!Expect(error == nil, @"Expected no error from discovery use case.")) {
            return 1;
        }
        if (!Expect(result.count == 1, @"Expected one supported device.")) {
            return 1;
        }

        MLDMouseDevice *first = result.firstObject;
        if (!Expect(first.vendorID == 0x09DA, @"Expected vendor ID to match Bloody vendor.")) {
            return 1;
        }
        if (!Expect(first.productID == 0x7B22, @"Expected product ID to match supported device.")) {
            return 1;
        }
    }

    return 0;
}
