#import "adapters/outbound/memory/MLDInMemoryFeatureTransportAdapter.h"

#import "domain/entities/MLDMouseDevice.h"
#import "domain/value_objects/MLDPerformanceProfile.h"
#include <string.h>

static NSString *const MLDInMemoryFeatureErrorDomain = @"com.mloody.adapters.memory.feature";

@interface MLDInMemoryFeatureTransportAdapter ()

@property(nonatomic, strong, readwrite, nullable) MLDMouseDevice *lastDevice;
@property(nonatomic, strong, readwrite, nullable) MLDPerformanceProfile *lastProfile;
@property(nonatomic, strong) NSMutableDictionary<NSNumber *, NSData *> *mutableReports;

@end

@implementation MLDInMemoryFeatureTransportAdapter

- (instancetype)init {
    self = [super init];
    if (self == nil) {
        return nil;
    }

    _shouldFail = NO;
    _failureReason = @"Forced in-memory adapter failure.";
    _mutableReports = [NSMutableDictionary dictionary];
    return self;
}

- (BOOL)applyPerformanceProfile:(MLDPerformanceProfile *)profile
                       toDevice:(MLDMouseDevice *)device
                          error:(NSError **)error {
    if (self.shouldFail) {
        if (error != nil) {
            *error = [NSError errorWithDomain:MLDInMemoryFeatureErrorDomain
                                         code:1
                                     userInfo:@{NSLocalizedDescriptionKey : self.failureReason}];
        }
        return NO;
    }

    self.lastDevice = device;
    self.lastProfile = profile;
    return YES;
}

- (BOOL)writeFeatureReportWithID:(uint8_t)reportID
                         payload:(NSData *)payload
                        toDevice:(MLDMouseDevice *)device
                           error:(NSError **)error {
    if (self.shouldFail) {
        if (error != nil) {
            *error = [NSError errorWithDomain:MLDInMemoryFeatureErrorDomain
                                         code:1
                                     userInfo:@{NSLocalizedDescriptionKey : self.failureReason}];
        }
        return NO;
    }

    self.lastDevice = device;
    self.mutableReports[@(reportID)] = [payload copy];
    return YES;
}

- (nullable NSData *)readFeatureReportWithID:(uint8_t)reportID
                                      length:(NSUInteger)length
                                  fromDevice:(MLDMouseDevice *)device
                                       error:(NSError **)error {
    if (self.shouldFail) {
        if (error != nil) {
            *error = [NSError errorWithDomain:MLDInMemoryFeatureErrorDomain
                                         code:1
                                     userInfo:@{NSLocalizedDescriptionKey : self.failureReason}];
        }
        return nil;
    }

    self.lastDevice = device;
    NSData *stored = self.mutableReports[@(reportID)];
    if (stored == nil) {
        if (error != nil) {
            NSString *message = [NSString stringWithFormat:@"No mock feature report for report id 0x%02x.", reportID];
            *error = [NSError errorWithDomain:MLDInMemoryFeatureErrorDomain
                                         code:2
                                     userInfo:@{NSLocalizedDescriptionKey : message}];
        }
        return nil;
    }

    if (stored.length == length) {
        return [stored copy];
    }

    NSMutableData *result = [NSMutableData dataWithLength:length];
    NSUInteger copyLength = MIN(length, stored.length);
    if (copyLength > 0) {
        memcpy(result.mutableBytes, stored.bytes, copyLength);
    }
    return [result copy];
}

- (void)setMockFeatureReportData:(NSData *)data forReportID:(uint8_t)reportID {
    self.mutableReports[@(reportID)] = [data copy];
}

- (NSDictionary<NSNumber *,NSData *> *)writtenReports {
    return [self.mutableReports copy];
}

@end
