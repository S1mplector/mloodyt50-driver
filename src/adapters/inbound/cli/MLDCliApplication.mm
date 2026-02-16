#import "adapters/inbound/cli/MLDCliApplication.h"

#import "application/use_cases/MLDApplyPerformanceProfileUseCase.h"
#import "application/use_cases/MLDDiscoverSupportedDevicesUseCase.h"
#import "domain/entities/MLDMouseDevice.h"
#import "domain/value_objects/MLDPerformanceProfile.h"

@interface MLDCliApplication ()

@property(nonatomic, strong) MLDDiscoverSupportedDevicesUseCase *discoverUseCase;
@property(nonatomic, strong) MLDApplyPerformanceProfileUseCase *applyProfileUseCase;

@end

@implementation MLDCliApplication

- (instancetype)initWithDiscoverUseCase:(MLDDiscoverSupportedDevicesUseCase *)discoverUseCase
                    applyProfileUseCase:(MLDApplyPerformanceProfileUseCase *)applyProfileUseCase {
    self = [super init];
    if (self == nil) {
        return nil;
    }

    _discoverUseCase = discoverUseCase;
    _applyProfileUseCase = applyProfileUseCase;
    return self;
}

- (int)runWithArgc:(int)argc argv:(const char * _Nonnull const * _Nonnull)argv {
    NSMutableArray<NSString *> *arguments = [NSMutableArray array];
    for (int i = 1; i < argc; ++i) {
        [arguments addObject:[NSString stringWithUTF8String:argv[i]]];
    }

    if (arguments.count == 0 || [arguments.firstObject isEqualToString:@"help"]) {
        [self printUsage];
        return 0;
    }

    NSString *command = arguments.firstObject;
    if ([command isEqualToString:@"list"]) {
        return [self runListCommand];
    }

    if ([command isEqualToString:@"apply"]) {
        NSArray<NSString *> *commandArgs = [arguments subarrayWithRange:NSMakeRange(1, arguments.count - 1)];
        return [self runApplyCommandWithArguments:commandArgs];
    }

    fprintf(stderr, "Unknown command: %s\n", command.UTF8String);
    [self printUsage];
    return 1;
}

- (void)printUsage {
    printf("mloody commands:\n");
    printf("  list\n");
    printf("  apply [--dpi <value>] [--polling <value>] [--lod <value>]\n");
}

- (int)runListCommand {
    NSError *error = nil;
    NSArray<MLDMouseDevice *> *devices = [self.discoverUseCase execute:&error];
    if (error != nil) {
        fprintf(stderr, "Discovery error: %s\n", error.localizedDescription.UTF8String);
        return 1;
    }

    if (devices.count == 0) {
        printf("No supported Bloody devices found.\n");
        return 0;
    }

    for (MLDMouseDevice *device in devices) {
        printf("vendor=0x%04x product=0x%04x model=%s serial=%s\n",
               device.vendorID,
               device.productID,
               device.modelName.UTF8String,
               device.serialNumber.UTF8String);
    }

    return 0;
}

- (int)runApplyCommandWithArguments:(NSArray<NSString *> *)arguments {
    NSUInteger dpi = 1600;
    NSUInteger polling = 1000;
    NSUInteger liftOffDistance = 2;

    NSString *parseError = nil;
    if (![self parseApplyArguments:arguments dpi:&dpi polling:&polling lod:&liftOffDistance errorMessage:&parseError]) {
        fprintf(stderr, "%s\n", parseError.UTF8String);
        [self printUsage];
        return 1;
    }

    NSError *discoveryError = nil;
    NSArray<MLDMouseDevice *> *devices = [self.discoverUseCase execute:&discoveryError];
    if (discoveryError != nil) {
        fprintf(stderr, "Discovery error: %s\n", discoveryError.localizedDescription.UTF8String);
        return 1;
    }
    if (devices.count == 0) {
        fprintf(stderr, "No supported Bloody device found to apply profile.\n");
        return 1;
    }

    MLDMouseDevice *target = devices.firstObject;
    MLDPerformanceProfile *profile = [[MLDPerformanceProfile alloc] initWithDPI:dpi
                                                                   pollingRateHz:polling
                                                                 liftOffDistance:liftOffDistance];

    NSError *applyError = nil;
    BOOL success = [self.applyProfileUseCase executeForDevice:target profile:profile error:&applyError];
    if (!success) {
        NSString *errorMessage = applyError.localizedDescription ?: @"Unknown apply failure.";
        fprintf(stderr, "Apply error: %s\n", errorMessage.UTF8String);
        return 1;
    }

    printf("Applied profile to %s (dpi=%lu polling=%lu lod=%lu).\n",
           target.modelName.UTF8String,
           (unsigned long)dpi,
           (unsigned long)polling,
           (unsigned long)liftOffDistance);
    return 0;
}

- (BOOL)parseApplyArguments:(NSArray<NSString *> *)arguments
                        dpi:(NSUInteger *)dpi
                    polling:(NSUInteger *)polling
                        lod:(NSUInteger *)lod
               errorMessage:(NSString **)errorMessage {
    NSUInteger index = 0;
    while (index < arguments.count) {
        NSString *key = arguments[index];

        if (index + 1 >= arguments.count) {
            if (errorMessage != nil) {
                *errorMessage = [NSString stringWithFormat:@"Missing value for argument '%@'.", key];
            }
            return NO;
        }

        NSString *value = arguments[index + 1];
        NSInteger numericValue = value.integerValue;
        if (numericValue <= 0) {
            if (errorMessage != nil) {
                *errorMessage = [NSString stringWithFormat:@"Argument '%@' must be a positive integer.", key];
            }
            return NO;
        }

        if ([key isEqualToString:@"--dpi"]) {
            *dpi = (NSUInteger)numericValue;
        } else if ([key isEqualToString:@"--polling"]) {
            *polling = (NSUInteger)numericValue;
        } else if ([key isEqualToString:@"--lod"]) {
            *lod = (NSUInteger)numericValue;
        } else {
            if (errorMessage != nil) {
                *errorMessage = [NSString stringWithFormat:@"Unknown argument '%@'.", key];
            }
            return NO;
        }

        index += 2;
    }

    return YES;
}

@end
