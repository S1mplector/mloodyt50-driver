#import <Foundation/Foundation.h>

#import "adapters/outbound/memory/MLDInMemoryFeatureTransportAdapter.h"
#import "application/ports/MLDFeatureTransportPort.h"
#import "application/use_cases/MLDT50ExchangeVendorCommandUseCase.h"
#import "domain/entities/MLDMouseDevice.h"
#include <string.h>

static BOOL Expect(BOOL condition, NSString *message) {
    if (!condition) {
        fprintf(stderr, "Assertion failed: %s\n", message.UTF8String);
        return NO;
    }
    return YES;
}

@interface MLDRecordingFeatureTransportSpy : NSObject <MLDFeatureTransportPort>

@property(nonatomic, assign) BOOL shouldFail;
@property(nonatomic, strong) NSMutableArray<NSData *> *writes;
@property(nonatomic, strong, nullable) NSData *forcedReadPayload;

@end

@implementation MLDRecordingFeatureTransportSpy

- (instancetype)init {
    self = [super init];
    if (self == nil) {
        return nil;
    }

    _shouldFail = NO;
    _writes = [NSMutableArray array];
    _forcedReadPayload = nil;
    return self;
}

- (BOOL)applyPerformanceProfile:(MLDPerformanceProfile *)profile
                       toDevice:(MLDMouseDevice *)device
                          error:(NSError **)error {
    if (self.shouldFail && error != nil) {
        *error = [NSError errorWithDomain:@"test.transport"
                                     code:1
                                 userInfo:@{NSLocalizedDescriptionKey : @"forced apply failure"}];
    }
    return !self.shouldFail;
}

- (BOOL)writeFeatureReportWithID:(uint8_t)reportID
                         payload:(NSData *)payload
                        toDevice:(MLDMouseDevice *)device
                           error:(NSError **)error {
    if (self.shouldFail) {
        if (error != nil) {
            *error = [NSError errorWithDomain:@"test.transport"
                                         code:2
                                     userInfo:@{NSLocalizedDescriptionKey : @"forced write failure"}];
        }
        return NO;
    }

    (void)reportID;
    (void)device;
    [self.writes addObject:[payload copy]];
    return YES;
}

- (nullable NSData *)readFeatureReportWithID:(uint8_t)reportID
                                      length:(NSUInteger)length
                                  fromDevice:(MLDMouseDevice *)device
                                       error:(NSError **)error {
    if (self.shouldFail) {
        if (error != nil) {
            *error = [NSError errorWithDomain:@"test.transport"
                                         code:3
                                     userInfo:@{NSLocalizedDescriptionKey : @"forced read failure"}];
        }
        return nil;
    }

    (void)reportID;
    (void)device;

    NSData *lastWrite = self.forcedReadPayload ?: self.writes.lastObject ?: [NSData data];
    NSMutableData *response = [NSMutableData dataWithLength:length];
    NSUInteger copyLength = MIN(length, lastWrite.length);
    if (copyLength > 0) {
        memcpy(response.mutableBytes, lastWrite.bytes, copyLength);
    }
    return response;
}

@end

int main(void) {
    @autoreleasepool {
        MLDInMemoryFeatureTransportAdapter *transport = [[MLDInMemoryFeatureTransportAdapter alloc] init];
        MLDT50ExchangeVendorCommandUseCase *useCase =
            [[MLDT50ExchangeVendorCommandUseCase alloc] initWithFeatureTransportPort:transport];

        MLDMouseDevice *device = [[MLDMouseDevice alloc] initWithVendorID:0x09DA
                                                                 productID:0x7F8D
                                                                 modelName:@"Bloody T50"
                                                              serialNumber:@"T50-TEST"];

        const uint8_t payloadBytes[] = {0x01, 0x02, 0x03};
        NSData *payload = [NSData dataWithBytes:payloadBytes length:sizeof(payloadBytes)];

        NSError *exchangeError = nil;
        NSData *response = [useCase executeForDevice:device
                                              opcode:0x22
                                           writeFlag:0x80
                                       payloadOffset:8
                                             payload:payload
                                               error:&exchangeError];
        if (!Expect(response != nil, @"Expected T50 exchange response data.")) {
            return 1;
        }
        if (!Expect(exchangeError == nil, @"Expected no error for valid T50 exchange.")) {
            return 1;
        }
        if (!Expect(response.length == [MLDT50ExchangeVendorCommandUseCase packetLength],
                    @"Expected fixed 72-byte response length.")) {
            return 1;
        }

        const uint8_t *responseBytes = (const uint8_t *)response.bytes;
        if (!Expect(responseBytes[0] == 0x07, @"Expected T50 magic byte in command packet.")) {
            return 1;
        }
        if (!Expect(responseBytes[1] == 0x22, @"Expected opcode to be set in command packet.")) {
            return 1;
        }
        if (!Expect(responseBytes[4] == 0x80, @"Expected write flag to be encoded in packet.")) {
            return 1;
        }
        if (!Expect(responseBytes[8] == 0x01 && responseBytes[9] == 0x02 && responseBytes[10] == 0x03,
                    @"Expected payload bytes to be copied at offset.")) {
            return 1;
        }

        NSError *invalidOffsetError = nil;
        NSData *invalid = [useCase executeForDevice:device
                                             opcode:0x22
                                          writeFlag:0x80
                                      payloadOffset:71
                                            payload:[NSData dataWithBytes:payloadBytes length:2]
                                              error:&invalidOffsetError];
        if (!Expect(invalid == nil, @"Expected overflow payload to fail.")) {
            return 1;
        }
        if (!Expect(invalidOffsetError != nil, @"Expected error for overflow payload.")) {
            return 1;
        }
        if (!Expect(invalidOffsetError.code == MLDT50ControlErrorCodePayloadTooLarge,
                    @"Expected payload-too-large error code.")) {
            return 1;
        }

        NSError *backlightError = nil;
        BOOL invalidBacklight = [useCase setBacklightLevel:5 onDevice:device error:&backlightError];
        if (!Expect(!invalidBacklight, @"Expected invalid backlight level to fail.")) {
            return 1;
        }
        if (!Expect(backlightError != nil, @"Expected backlight validation error.")) {
            return 1;
        }

        NSError *coreSetError = nil;
        BOOL coreSetOK = [useCase setCoreSlotCandidate:3 onDevice:device error:&coreSetError];
        if (!Expect(coreSetOK, @"Expected core slot candidate write to succeed.")) {
            return 1;
        }
        if (!Expect(coreSetError == nil, @"Expected no error for valid core slot candidate.")) {
            return 1;
        }

        NSData *corePacket = transport.writtenReports[@([MLDT50ExchangeVendorCommandUseCase reportID])];
        if (!Expect(corePacket != nil, @"Expected core candidate packet to be written.")) {
            return 1;
        }
        const uint8_t *corePacketBytes = (const uint8_t *)corePacket.bytes;
        if (!Expect(corePacketBytes[1] == 0x0c && corePacketBytes[4] == 0x00 && corePacketBytes[8] == 0x06 &&
                        corePacketBytes[9] == 0x80 && corePacketBytes[10] == 0x03,
                    @"Expected core candidate packet bytes to match 0x0c / 06 80 <slot> pattern.")) {
            return 1;
        }

        NSError *invalidCoreError = nil;
        BOOL invalidCore = [useCase setCoreSlotCandidate:0 onDevice:device error:&invalidCoreError];
        if (!Expect(!invalidCore, @"Expected out-of-range core slot to fail.")) {
            return 1;
        }
        if (!Expect(invalidCoreError != nil, @"Expected error for out-of-range core slot.")) {
            return 1;
        }
        if (!Expect(invalidCoreError.code == MLDT50ControlErrorCodeInvalidCoreSlot,
                    @"Expected invalid-core-slot error code.")) {
            return 1;
        }

        MLDRecordingFeatureTransportSpy *coreReadSpy = [[MLDRecordingFeatureTransportSpy alloc] init];
        NSMutableData *coreReadResponse = [NSMutableData dataWithLength:[MLDT50ExchangeVendorCommandUseCase packetLength]];
        uint8_t *coreReadBytes = (uint8_t *)coreReadResponse.mutableBytes;
        coreReadBytes[0] = 0x07;
        coreReadBytes[1] = 0x1e;
        coreReadBytes[10] = 0x04;
        coreReadSpy.forcedReadPayload = coreReadResponse;
        MLDT50ExchangeVendorCommandUseCase *coreReadUseCase =
            [[MLDT50ExchangeVendorCommandUseCase alloc] initWithFeatureTransportPort:coreReadSpy];

        NSError *coreReadError = nil;
        NSNumber *coreSlot = [coreReadUseCase readCoreSlotCandidateForDevice:device error:&coreReadError];
        if (!Expect(coreSlot != nil, @"Expected core candidate read to return value.")) {
            return 1;
        }
        if (!Expect(coreReadError == nil, @"Expected no error for core candidate read.")) {
            return 1;
        }
        if (!Expect(coreSlot.unsignedIntegerValue == 4, @"Expected core candidate read to parse byte 10.")) {
            return 1;
        }

        MLDRecordingFeatureTransportSpy *saveSpy = [[MLDRecordingFeatureTransportSpy alloc] init];
        MLDT50ExchangeVendorCommandUseCase *saveUseCase =
            [[MLDT50ExchangeVendorCommandUseCase alloc] initWithFeatureTransportPort:saveSpy];

        NSError *saveError = nil;
        BOOL quickSaved = [saveUseCase saveSettingsToDevice:device
                                                   strategy:MLDT50SaveStrategyQuick
                                                      error:&saveError];
        if (!Expect(quickSaved, @"Expected quick T50 save strategy to succeed.")) {
            return 1;
        }
        if (!Expect(saveError == nil, @"Expected no error for quick save strategy.")) {
            return 1;
        }
        if (!Expect(saveSpy.writes.count == [MLDT50ExchangeVendorCommandUseCase saveStepCountForStrategy:MLDT50SaveStrategyQuick],
                    @"Expected quick strategy to emit expected number of packets.")) {
            return 1;
        }

        const uint8_t *quickFirstPacket = (const uint8_t *)saveSpy.writes.firstObject.bytes;
        if (!Expect(quickFirstPacket[0] == 0x07 && quickFirstPacket[1] == 0x03 &&
                        quickFirstPacket[2] == 0x03 && quickFirstPacket[3] == 0x0B && quickFirstPacket[4] == 0x01,
                    @"Expected quick save arm packet bytes to match capture candidate.")) {
            return 1;
        }
        const uint8_t *quickLastPacket = (const uint8_t *)saveSpy.writes.lastObject.bytes;
        if (!Expect(quickLastPacket[2] == 0x03 && quickLastPacket[3] == 0x0B && quickLastPacket[4] == 0x00,
                    @"Expected quick save release packet bytes to match capture candidate.")) {
            return 1;
        }

        [saveSpy.writes removeAllObjects];
        NSError *captureSaveError = nil;
        BOOL captureSaved = [saveUseCase saveSettingsToDevice:device
                                                     strategy:MLDT50SaveStrategyCaptureV1
                                                        error:&captureSaveError];
        if (!Expect(captureSaved, @"Expected capture-v1 T50 save strategy to succeed.")) {
            return 1;
        }
        if (!Expect(captureSaveError == nil, @"Expected no error for capture-v1 save strategy.")) {
            return 1;
        }
        if (!Expect(saveSpy.writes.count ==
                        [MLDT50ExchangeVendorCommandUseCase saveStepCountForStrategy:MLDT50SaveStrategyCaptureV1],
                    @"Expected capture-v1 strategy to emit expected number of packets.")) {
            return 1;
        }

        const uint8_t *captureFirstPacket = (const uint8_t *)saveSpy.writes.firstObject.bytes;
        if (!Expect(captureFirstPacket[1] == 0x03 && captureFirstPacket[2] == 0x06 && captureFirstPacket[3] == 0x05,
                    @"Expected capture-v1 first packet to start with 03 06 05.")) {
            return 1;
        }
        const uint8_t *captureLastPacket = (const uint8_t *)saveSpy.writes.lastObject.bytes;
        if (!Expect(captureLastPacket[1] == 0x03 && captureLastPacket[2] == 0x03 &&
                        captureLastPacket[3] == 0x0B && captureLastPacket[4] == 0x00,
                    @"Expected capture-v1 last packet to release save latch.")) {
            return 1;
        }

        MLDRecordingFeatureTransportSpy *failingSpy = [[MLDRecordingFeatureTransportSpy alloc] init];
        failingSpy.shouldFail = YES;
        MLDT50ExchangeVendorCommandUseCase *failingUseCase =
            [[MLDT50ExchangeVendorCommandUseCase alloc] initWithFeatureTransportPort:failingSpy];
        NSError *failingSaveError = nil;
        BOOL failingSave = [failingUseCase saveSettingsToDevice:device
                                                       strategy:MLDT50SaveStrategyQuick
                                                          error:&failingSaveError];
        if (!Expect(!failingSave, @"Expected save strategy to fail when transport fails.")) {
            return 1;
        }
        if (!Expect(failingSaveError != nil, @"Expected error for failed save strategy.")) {
            return 1;
        }
        if (!Expect(failingSaveError.code == MLDT50ControlErrorCodeSaveSequenceFailed,
                    @"Expected save failure error code for transport failure.")) {
            return 1;
        }
    }

    return 0;
}
