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

/// 自定义结构体（v1.5 测试对照）：无预编译裸字节 IMP，仍走 forwardInvocation 转发路径
/// （含 padding 空洞——int32+double 对齐为 16B，NSValue 装箱存储，不涉及 memcmp）
typedef struct {
    int32_t a;
    double b;
} CBTestCustomStruct;

/// 大自定义结构体（256B：32 个 double）：无预编译 IMP，走转发——验证转发对任意大小
/// 结构体（>16B sret + 引用传参）的正确性
typedef struct {
    double d[32];
} CBTestBigStruct;

/// 联合体（边界锁死用例）：CBModel 对 union 属性不做支持（NSMethodSignature 不支持
/// union '(' 编码），访问时抛 NSInvalidArgumentException 而非崩溃，测试锁定此边界
typedef union {
    int i;
    double d;
    char bytes[8];
} CBTestUnion;

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
/// 自定义结构体（v1.5 对照）：无预编译 IMP，仍走 forwardInvocation 转发路径
@property (nonatomic) CBTestCustomStruct customStructValue;
/// 大结构体 256B：无预编译 IMP，走转发（任意大小）；联合体：边界锁死（明确抛异常）
@property (nonatomic) CBTestBigStruct bigStructValue;
@property (nonatomic) CBTestUnion unionValue;

#pragma mark - Atomic 结构体属性

@property (atomic) CGPoint atomicPointValue;
@property (atomic) CGRect atomicRectValue;
/// atomic 大结构体（128B RawBig + 锁内 memcpy，v1.5 盲点加固）
@property (atomic) CATransform3D atomicTransform3DValue;

#pragma mark - 自定义 getter/setter 名称

@property (nonatomic, getter=isCurrent) BOOL current;
@property (nonatomic, setter=setSpecialName:) NSString *specialName;

#pragma mark - readonly 属性（P2：只注入 getter、不注入 setter）

@property (nonatomic, readonly) NSInteger readonlyIntValue;
@property (nonatomic, readonly, strong) NSString *readonlyString;
@property (nonatomic, readonly) CGPoint readonlyPointValue;

@end

#pragma mark - 类级缓存竞态测试模型（P0-2.3）

/// 仅供 testClassLevelCacheConcurrentResolve 使用：保证本类的 selector
/// 首次解析（resolveInstanceMethod:）恰好发生在并发阶段，从而并发写类级缓存。
/// 属性用 atomic：并发写入有槽锁保护（去锁重构后 non-atomic 无锁，并发写属误用），
/// 本测试只关心"并发首次解析"的类级缓存竞态，不涉及 non-atomic 值语义。
@interface ResolveRaceModel : CBModel
@property (atomic) NSInteger propA;
@property (atomic) NSInteger propB;
@property (atomic) NSInteger propC;
@property (atomic) NSInteger propD;
@property (atomic) NSInteger propE;
@property (atomic, strong) NSString *strF;
@property (atomic, strong) NSString *strG;
@property (atomic, strong) NSString *strH;
@end

/// 第二组全新类：跨类并发首次解析，规避 runtime 对同一类解析的潜在串行化
@interface ResolveRaceModel2 : CBModel
@property (atomic) NSInteger propA;
@property (atomic) NSInteger propB;
@property (atomic) NSInteger propC;
@property (atomic) NSInteger propD;
@property (atomic, strong) NSString *strE;
@property (atomic, strong) NSString *strF;
@end

#pragma mark - 协议属性相等性测试模型（P2）

/// 带协议属性的模型：验证 isEqual/hash 对协议注入属性的覆盖（协议属性 + 类内属性混合）
@protocol CBProtocolPropTestProtocol <NSObject>
@property (nonatomic) NSInteger protocolInt;
@property (nonatomic, strong) NSString *protocolString;
@end

@interface ProtocolPropModel : CBModel <CBProtocolPropTestProtocol>
@property (nonatomic) NSInteger ownInt;
@end

#pragma mark - 类属性测试模型（P2）

/// 类属性（class property）：getter/setter 是类方法，由 resolveClassMethod: 注入，值 per-class 存储
@interface ClassPropModel : CBModel
@property (class, nonatomic, strong) NSString *sharedName;
@property (class, nonatomic, copy) NSString *sharedCopy;
@property (class, nonatomic) NSInteger sharedCount;
@property (class, nonatomic, weak) id sharedWeak;
@property (class, nonatomic, readonly) NSInteger sharedReadonly;
@end
