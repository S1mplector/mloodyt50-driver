#import <Foundation/Foundation.h>

#import "adapters/outbound/memory/MLDInMemoryFeatureTransportAdapter.h"
#import "application/use_cases/MLDReadFeatureReportUseCase.h"
#import "application/use_cases/MLDWriteFeatureReportUseCase.h"
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
        MLDInMemoryFeatureTransportAdapter *transport = [[MLDInMemoryFeatureTransportAdapter alloc] init];
        MLDWriteFeatureReportUseCase *writeUseCase =
            [[MLDWriteFeatureReportUseCase alloc] initWithFeatureTransportPort:transport];
        MLDReadFeatureReportUseCase *readUseCase =
            [[MLDReadFeatureReportUseCase alloc] initWithFeatureTransportPort:transport];

        MLDMouseDevice *device = [[MLDMouseDevice alloc] initWithVendorID:0x09DA
                                                                 productID:0x1001
                                                                 modelName:@"Bloody T50"
                                                              serialNumber:@"TEST-001"];

        const uint8_t payloadBytes[] = {0x11, 0x22, 0x33};
        NSData *payload = [NSData dataWithBytes:payloadBytes length:sizeof(payloadBytes)];

        NSError *writeError = nil;
        BOOL writeOK = [writeUseCase executeForDevice:device reportID:0x07 payload:payload error:&writeError];
        if (!Expect(writeOK, @"Expected write use case to succeed.")) {
            return 1;
        }
        if (!Expect(writeError == nil, @"Expected no write error.")) {
            return 1;
        }

        NSError *readError = nil;
        NSData *readData = [readUseCase executeForDevice:device reportID:0x07 length:3 error:&readError];
        if (!Expect(readData != nil, @"Expected read use case to return data.")) {
            return 1;
        }
        if (!Expect(readError == nil, @"Expected no read error.")) {
            return 1;
        }
        if (!Expect([readData isEqualToData:payload], @"Expected read data to match written data.")) {
            return 1;
        }

        NSData *paddedRead = [readUseCase executeForDevice:device reportID:0x07 length:5 error:&readError];
        if (!Expect(paddedRead != nil, @"Expected padded read to succeed.")) {
            return 1;
        }
        if (!Expect(paddedRead.length == 5, @"Expected padded read length to match request.")) {
            return 1;
        }
        const uint8_t *bytes = (const uint8_t *)paddedRead.bytes;
        if (!Expect(bytes[0] == 0x11 && bytes[1] == 0x22 && bytes[2] == 0x33,
                    @"Expected padded read prefix to keep original payload.")) {
            return 1;
        }

        NSError *missingError = nil;
        NSData *missing = [readUseCase executeForDevice:device reportID:0x09 length:4 error:&missingError];
        if (!Expect(missing == nil, @"Expected missing report to return nil.")) {
            return 1;
        }
        if (!Expect(missingError != nil, @"Expected error for missing report.")) {
            return 1;
        }
    }

    return 0;
}
