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
///
/// 已支持一下常用类型：
/// - c  表示char类型
/// - i  表示int类型
/// - s  表示short类型
/// - l  表示long类型
/// - q  表示long long类型
/// - C  表示unsigned char类型
/// - I  表示unsigned int类型
/// - S  表示unsigned short类型
/// - L  表示unsigned long类型
/// - Q  表示unsigned long long类型
/// - f  表示float类型
/// - d  表示double类型
/// - B  表示BOOL类型
/// - v  表示void类型
/// - \*  表示char *类型（C字符串）
/// - @  表示对象类型（id类型），后面可以跟随一个字符串，表示对象的类名，例如@"NSString"表示NSString类对象
/// - #  表示类类型（Class类型）
/// - :  表示方法选择器（SEL类型）
/// - [arrayType]  表示数组类型，其中arrayType是数组元素的编码类型，例如[NSString]表示NSString类型的数组
/// - {name=type}  表示结构体类型，其中name是结构体名称，type是结构体的编码类型，例如{CGPoint=dd}表示CGPoint结构体类型，包含两个double类型的成员变量
/// - (name=type)  表示联合体类型，与结构体类似

@interface CBModel : NSObject
@property(nonatomic, readonly) NSMutableDictionary<NSString*, id>* sDynamicProperties;// 存放强引用的动态属性
@property(nonatomic, readonly) NSMapTable<NSString*, id>* wDynamicProperties;// 存放弱引用的动态属性
@end

NS_ASSUME_NONNULL_END
