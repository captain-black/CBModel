//
//  CBModel.h
//  CBModel
//
//  Created by Captain Black on 12/28/2022.
//  Copyright (c) 2022 Captain Black. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 自动映射 property 的getter、setter实现
/// !!!: 目前不支持atomic修饰符的原子性同步锁功能
@interface CBModel : NSObject
@property(nonatomic, readonly) NSMutableDictionary<NSString*, id>* sDynamicProperties;// 存放强引用的动态属性
@property(nonatomic, readonly) NSMapTable<NSString*, id>* wDynamicProperties;// 存放弱引用的动态属性
@end

NS_ASSUME_NONNULL_END
