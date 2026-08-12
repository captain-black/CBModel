//
//  TestModel.h
//  CBModelTests
//
//  Created by Captain Black on 2023/7/14.
//  Copyright (c) 2023 Captain Black. All rights reserved.
//

#import "CBModel.h"
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface TestModel : CBModel

@property (nonatomic) NSInteger intValue;
@property (nonatomic) long double ldValue;
@property (nonatomic) CGFloat floatValue;
@property (nonatomic) double doubleValue;
@property (nonatomic) BOOL boolValue;
@property (nonatomic) char charValue;
@property (nonatomic) short shortValue;
@property (nonatomic) long long longValue;
@property (nonatomic) unsigned int unsignedIntValue;
@property (nonatomic) unsigned long long unsignedLongLongValue;

@property (nonatomic, strong) NSString *strongString;
@property (nonatomic, copy) NSString *cpString;
@property (nonatomic, weak) id weakObject;

@property (atomic) NSInteger atomicIntValue;
@property (atomic, strong) NSString *atomicString;

// 大量 atomic 属性：用于容器竞态回归测试（并发首写触发字典扩容 rehash 竞态）
@property (atomic) double atomicDoubleValue1;
@property (atomic) double atomicDoubleValue2;
@property (atomic) double atomicDoubleValue3;
@property (atomic) double atomicDoubleValue4;
@property (atomic) double atomicDoubleValue5;
@property (atomic) double atomicDoubleValue6;
@property (atomic) double atomicDoubleValue7;
@property (atomic) double atomicDoubleValue8;
@property (atomic) double atomicDoubleValue9;
@property (atomic) double atomicDoubleValue10;
@property (atomic) double atomicDoubleValue11;
@property (atomic) double atomicDoubleValue12;
@property (atomic) double atomicDoubleValue13;
@property (atomic) double atomicDoubleValue14;
@property (atomic) double atomicDoubleValue15;
@property (atomic) double atomicDoubleValue16;
@property (atomic, strong) NSString *atomicExtraString1;
@property (atomic, strong) NSString *atomicExtraString2;
@property (atomic, strong) NSString *atomicExtraString3;
@property (atomic, strong) NSString *atomicExtraString4;
@property (atomic, strong) NSString *atomicExtraString5;
@property (atomic, strong) NSString *atomicExtraString6;
@property (atomic, strong) NSString *atomicExtraString7;
@property (atomic, strong) NSString *atomicExtraString8;

@property (nonatomic, strong) NSArray *arrayValue;
@property (nonatomic, strong) NSDictionary *dictValue;

#pragma mark - 结构体属性

@property (nonatomic) CGPoint pointValue;
@property (nonatomic) CGSize sizeValue;
@property (nonatomic) CGRect rectValue;
@property (nonatomic) UIEdgeInsets edgeInsetsValue;
@property (nonatomic) NSRange rangeValue;
@property (nonatomic) CGAffineTransform transformValue;
@property (nonatomic) CATransform3D transform3DValue;

#pragma mark - Atomic 结构体属性

@property (atomic) CGPoint atomicPointValue;
@property (atomic) CGRect atomicRectValue;

#pragma mark - 自定义 getter/setter 名称

@property (nonatomic, getter=isCurrent) BOOL current;
@property (nonatomic, setter=setSpecialName:) NSString *specialName;

@end
