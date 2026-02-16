#import <Foundation/Foundation.h>

@class MLDApplyPerformanceProfileUseCase;
@class MLDDiscoverSupportedDevicesUseCase;

NS_ASSUME_NONNULL_BEGIN

@interface MLDCliApplication : NSObject

- (instancetype)initWithDiscoverUseCase:(MLDDiscoverSupportedDevicesUseCase *)discoverUseCase
                    applyProfileUseCase:(MLDApplyPerformanceProfileUseCase *)applyProfileUseCase NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

- (int)runWithArgc:(int)argc argv:(const char * _Nonnull const * _Nonnull)argv;

@end

NS_ASSUME_NONNULL_END
