//
//  CBModel.h
//  CBModel
//
//  Created by Captain Black on 2022/8/9.
//

#import <Foundation/Foundation.h>

#import <YYModel/YYModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CBModel : NSObject <YYModel>

@property (nonatomic, copy, class) NSDictionary<NSString*, id>* modelCustomPropertyMapper;
@property (nonatomic, copy, class) NSDictionary<NSString*, id>* modelContainerPropertyGenericClass;

+ (nullable NSDictionary<NSString *,id> *)modelCustomPropertyMapper NS_REQUIRES_SUPER;

+ (nullable NSDictionary<NSString *,id> *)modelContainerPropertyGenericClass NS_REQUIRES_SUPER;

@end

NS_ASSUME_NONNULL_END
