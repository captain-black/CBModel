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

@property(nonatomic, readonly, class) NSArray<Class>* _Nullable proxyClasses;

+ (void)addProxyClass:(Class)cls;

@end

NS_ASSUME_NONNULL_END
