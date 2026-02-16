#import "domain/entities/MLDMouseDevice.h"

@implementation MLDMouseDevice

- (instancetype)initWithVendorID:(uint16_t)vendorID
                       productID:(uint16_t)productID
                       modelName:(NSString *)modelName
                    serialNumber:(NSString *)serialNumber {
    self = [super init];
    if (self == nil) {
        return nil;
    }

    _vendorID = vendorID;
    _productID = productID;
    _modelName = [modelName copy];
    _serialNumber = [serialNumber copy];
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<MLDMouseDevice vendor=0x%04x product=0x%04x model=%@ serial=%@>",
                                      self.vendorID,
                                      self.productID,
                                      self.modelName,
                                      self.serialNumber];
}

@end
