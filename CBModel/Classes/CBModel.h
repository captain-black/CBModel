//
//  CBModel.h
//  CBModel
//
//  Created by Captain Black on 12/28/2022.
//  Copyright (c) 2022 Captain Black. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 自动映射 property 的 getter、setter 实现
///
/// 已支持以下类型：
/// char, int, short, long, long long, unsigned char, unsigned int, unsigned short, unsigned long,
/// unsigned long long, float, double, long double, BOOL, 指针(void* | char* | int*),
/// 对象(id | NSObject*，strong/copy/weak), Class, SEL,
/// 已知结构体(CGPoint/CGSize/CGRect/NSRange/UIEdgeInsets/CGAffineTransform/CATransform3D，预编译 IMP),
/// 自定义结构体(forwardInvocation 兜底)
/// - 支持原子性 atomic（per-属性锁）
/// - 支持 KVC、KVO、readonly、类属性、isEqual:/hash、运行时动态类（插件化）
/// - 不支持：union、C 数组属性（明确报错/不可声明）
@interface CBModel : NSObject
@end

NS_ASSUME_NONNULL_END
