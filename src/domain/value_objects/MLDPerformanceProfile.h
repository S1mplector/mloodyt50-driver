#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MLDPerformanceProfile : NSObject

@property(nonatomic, assign, readonly) NSUInteger dpi;
@property(nonatomic, assign, readonly) NSUInteger pollingRateHz;
@property(nonatomic, assign, readonly) NSUInteger liftOffDistance;

- (instancetype)initWithDPI:(NSUInteger)dpi
              pollingRateHz:(NSUInteger)pollingRateHz
            liftOffDistance:(NSUInteger)liftOffDistance NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
