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
///
/// 已支持一下常用类型：
/// char, int, short, long, long long, unsigned char, unsigned int, unsigned short, unsigned long, unsigned long long, float, double, BOOL, Pointer(void* | chat* | int*), (id | NSObject*), Class, SEL, Array, Struct, Union
/// - 支持原子性 atomic
/// - 支持KVC、KVO
@interface CBModel : NSObject <NSCoding, NSCopying>
@property(readonly) NSMutableDictionary<NSString*, id>* sDynamicProperties;
@property(readonly) NSMapTable<NSString*, id>* wDynamicProperties;
@property(readonly) NSMutableDictionary<NSString*, NSLock*>* propertyLocks;
@end

NS_ASSUME_NONNULL_END
