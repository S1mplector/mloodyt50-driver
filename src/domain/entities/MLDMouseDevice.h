#import <Foundation/Foundation.h>
#include <stdint.h>

NS_ASSUME_NONNULL_BEGIN

@interface MLDMouseDevice : NSObject

@property(nonatomic, assign, readonly) uint16_t vendorID;
@property(nonatomic, assign, readonly) uint16_t productID;
@property(nonatomic, copy, readonly) NSString *modelName;
@property(nonatomic, copy, readonly) NSString *serialNumber;

- (instancetype)initWithVendorID:(uint16_t)vendorID
                       productID:(uint16_t)productID
                       modelName:(NSString *)modelName
                    serialNumber:(NSString *)serialNumber NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
