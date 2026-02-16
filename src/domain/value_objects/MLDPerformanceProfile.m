#import "domain/value_objects/MLDPerformanceProfile.h"

@implementation MLDPerformanceProfile

- (instancetype)initWithDPI:(NSUInteger)dpi
              pollingRateHz:(NSUInteger)pollingRateHz
            liftOffDistance:(NSUInteger)liftOffDistance {
    self = [super init];
    if (self == nil) {
        return nil;
    }

    _dpi = dpi;
    _pollingRateHz = pollingRateHz;
    _liftOffDistance = liftOffDistance;
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<MLDPerformanceProfile dpi=%lu polling=%luHz lod=%lu>",
                                      (unsigned long)self.dpi,
                                      (unsigned long)self.pollingRateHz,
                                      (unsigned long)self.liftOffDistance];
}

@end
