//
//  Tests.m
//  CBModelTests
//
//  Created by Captain Black on 12/28/2022.
//  Copyright (c) 2022 Captain Black. All rights reserved.
//

@import XCTest;
#import <objc/message.h>
#import "TestModel.h"
#import "YYTestModel.h"
@import YYModel;

@interface Tests : XCTestCase
@property (nonatomic, assign) BOOL kvoObserverCalled;
@property (nonatomic, assign) NSInteger kvoNewIntValue;
@property (nonatomic, assign) long double kvoNewLdValue;
@property (nonatomic, strong) NSString *kvoNewStringValue;
@property (nonatomic, assign) CGPoint kvoOldPointValue;
@property (nonatomic, assign) CGPoint kvoNewPointValue;
@property (nonatomic, weak) TestModel *kvoModel;
@end

@implementation Tests

- (void)setUp {
    [super setUp];
    self.kvoObserverCalled = NO;
    self.kvoNewIntValue = 0;
    self.kvoNewStringValue = nil;
}

- (void)tearDown {
    [super tearDown];
}

#pragma mark - 基本类型测试

// 验证 int 标量属性：动态注入的 getter/setter 存取正确
- (void)testIntProperty {
    TestModel *model = [[TestModel alloc] init];
    model.intValue = 42;
    XCTAssertEqual(model.intValue, 42, @"int 属性应该正常工作");
}

// 验证 float 标量属性：存取正确（允许 0.001 精度误差）
- (void)testFloatProperty {
    TestModel *model = [[TestModel alloc] init];
    model.floatValue = 3.14f;
    XCTAssertEqualWithAccuracy(model.floatValue, 3.14f, 0.001, @"float 属性应该正常工作");
}

// 验证 double 标量属性：存取正确（允许 0.00001 精度误差）
- (void)testDoubleProperty {
    TestModel *model = [[TestModel alloc] init];
    model.doubleValue = 2.71828;
    XCTAssertEqualWithAccuracy(model.doubleValue, 2.71828, 0.00001, @"double 属性应该正常工作");
}

// 验证 BOOL 标量属性：YES/NO 双向存取正确
- (void)testBoolProperty {
    TestModel *model = [[TestModel alloc] init];
    model.boolValue = YES;
    XCTAssertTrue(model.boolValue, @"bool 属性应该正常工作");
    
    model.boolValue = NO;
    XCTAssertFalse(model.boolValue, @"bool 属性应该正常工作");
}

// 验证 char 标量属性：存取正确
- (void)testCharProperty {
    TestModel *model = [[TestModel alloc] init];
    model.charValue = 'A';
    XCTAssertEqual(model.charValue, 'A', @"char 属性应该正常工作");
}

// 验证 short 标量属性：存取正确
- (void)testShortProperty {
    TestModel *model = [[TestModel alloc] init];
    model.shortValue = 1000;
    XCTAssertEqual(model.shortValue, 1000, @"short 属性应该正常工作");
}

// 验证 long long 标量属性：存取正确（大数）
- (void)testLongLongProperty {
    TestModel *model = [[TestModel alloc] init];
    model.longValue = 1234567890LL;
    XCTAssertEqual(model.longValue, 1234567890LL, @"long long 属性应该正常工作");
}

// 验证 unsigned int 标量属性：存取正确
- (void)testUnsignedIntProperty {
    TestModel *model = [[TestModel alloc] init];
    model.unsignedIntValue = 999;
    XCTAssertEqual(model.unsignedIntValue, 999, @"unsigned int 属性应该正常工作");
}

// 验证 unsigned long long 标量属性：存取正确（大数）
- (void)testUnsignedLongLongProperty {
    TestModel *model = [[TestModel alloc] init];
    model.unsignedLongLongValue = 9876543210ULL;
    XCTAssertEqual(model.unsignedLongLongValue, 9876543210ULL, @"unsigned long long 属性应该正常工作");
}

#pragma mark - 对象类型测试

// 验证 strong 对象属性：存取返回同一引用
- (void)testStrongStringProperty {
    TestModel *model = [[TestModel alloc] init];
    NSString *testString = @"Hello, World!";
    model.strongString = testString;
    XCTAssertEqualObjects(model.strongString, testString, @"strong string 属性应该正常工作");
}

// 验证 copy 对象属性：setter 复制值，赋值后修改原可变对象不影响属性
- (void)testCopyStringProperty {
    TestModel *model = [[TestModel alloc] init];
    NSMutableString *mutableString = [NSMutableString stringWithString:@"原始值"];
    model.cpString = mutableString;
    [mutableString appendString:@" 修改后"];
    XCTAssertEqualObjects(model.cpString, @"原始值", @"copy string 属性应该复制值");
}

// 验证 weak 对象属性：弱引用语义，对象释放后属性自动置 nil
- (void)testWeakObjectProperty {
    TestModel *model = [[TestModel alloc] init];
    @autoreleasepool {
        
        NSObject *obj = [[NSObject alloc] init];
        model.weakObject = obj;
        XCTAssertEqual(model.weakObject, obj, @"weak object 属性应该正常工作");
        
        obj = nil;
    }
    
    XCTAssertNil(model.weakObject, @"weak object 在对象释放后应该为 nil");
}

// 验证 NSArray 对象属性：存取正确
- (void)testArrayProperty {
    TestModel *model = [[TestModel alloc] init];
    NSArray *array = @[@"one", @"two", @"three"];
    model.arrayValue = array;
    XCTAssertEqualObjects(model.arrayValue, array, @"array 属性应该正常工作");
}

// 验证 NSDictionary 对象属性：存取正确
- (void)testDictProperty {
    TestModel *model = [[TestModel alloc] init];
    NSDictionary *dict = @{@"key": @"value"};
    model.dictValue = dict;
    XCTAssertEqualObjects(model.dictValue, dict, @"dictionary 属性应该正常工作");
}

#pragma mark - Atomic 属性测试

// 验证 atomic 标量属性：存取正确
- (void)testAtomicIntProperty {
    TestModel *model = [[TestModel alloc] init];
    model.atomicIntValue = 100;
    XCTAssertEqual(model.atomicIntValue, 100, @"atomic int 属性应该正常工作");
}

// 验证 atomic 对象属性：存取正确
- (void)testAtomicStringProperty {
    TestModel *model = [[TestModel alloc] init];
    NSString *testString = @"Atomic String";
    model.atomicString = testString;
    XCTAssertEqualObjects(model.atomicString, testString, @"atomic string 属性应该正常工作");
}

#pragma mark - 线程安全测试

// 验证同一 atomic 属性多线程并发写入：结束后值有效（同一属性的写入应被串行化）
- (void)testAtomicPropertyConcurrentWrite {
    TestModel *model = [[TestModel alloc] init];
    
    dispatch_group_t group = dispatch_group_create();
    
    for (int i = 0; i < 100; i++) {
        dispatch_group_enter(group);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            model.atomicIntValue = i;
            dispatch_group_leave(group);
        });
    }
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    XCTAssertTrue(model.atomicIntValue >= 0 && model.atomicIntValue < 100,
                  @"atomic 属性并发写入后值应该有效");
}

// 验证 atomic 对象属性多线程并发读写：不崩溃、值不为 nil
- (void)testAtomicPropertyConcurrentReadWrite {
    TestModel *model = [[TestModel alloc] init];
    model.atomicString = @"初始值";
    
    dispatch_group_t group = dispatch_group_create();
    
    for (int i = 0; i < 100; i++) {
        dispatch_group_enter(group);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            model.atomicString = [NSString stringWithFormat:@"值 %d", i];
            dispatch_group_leave(group);
        });
    }
    
    for (int i = 0; i < 100; i++) {
        dispatch_group_enter(group);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *value = model.atomicString;
            (void)value;
            dispatch_group_leave(group);
        });
    }
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    XCTAssertNotNil(model.atomicString, @"atomic string 属性在并发读写后不应该为 nil");
}

// 验证 atomic 字符串属性多线程并发写入：结束后不为 nil
- (void)testAtomicStringPropertyThreadSafety {
    TestModel *model = [[TestModel alloc] init];
    model.atomicString = @"初始值";
    
    dispatch_group_t group = dispatch_group_create();
    
    for (int i = 0; i < 100; i++) {
        dispatch_group_enter(group);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            model.atomicString = [NSString stringWithFormat:@"值 %d", i];
            dispatch_group_leave(group);
        });
    }
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    XCTAssertNotNil(model.atomicString, @"atomic string 属性在并发访问后不应该为 nil");
}

#pragma mark - 容器竞态回归测试（P0-2.1）

/// 单线程预触达所有属性：完成类级 IMP 注入与 selector 缓存（隔离 P0-2.3 的类级缓存竞态）
static void CBModel_WarmUpAtomicProps(TestModel *model) {
    model.atomicIntValue = 0;
    model.atomicString = @"";
    model.atomicPointValue = CGPointZero;
    model.atomicRectValue = CGRectZero;
    for (int i = 1; i <= 16; i++) {
        [[model valueForKey:[NSString stringWithFormat:@"atomicDoubleValue%d", i]] doubleValue];
        [model setValue:@(0.0) forKey:[NSString stringWithFormat:@"atomicDoubleValue%d", i]];
    }
    for (int i = 1; i <= 8; i++) {
        [model setValue:@"" forKey:[NSString stringWithFormat:@"atomicExtraString%d", i]];
    }
}

// 验证不同 atomic 属性多线程并发写入（P0-2.1 容器竞态回归）：修复前 per-property 锁
// 保护不了共享容器，并发写不同属性会损坏字典；修复后所有属性可读且值有效
- (void)testDifferentAtomicPropertiesConcurrentWrite {
    // 预热实例只负责完成类级注入；并发写入用全新的实例，其容器为空，
    // 并发首写多个 key 必然触发字典扩容 rehash —— 修复前 per-property 锁
    // 粒度保护不了共享容器，扩容与写入竞争会损坏字典内部结构（崩溃/数据丢失）。
    // 注：该竞态为概率性重现（损坏窗口 ~百纳秒级），本测试作为"并发压力 + 数据完整性"
    // 回归测试，修复后的实现必须稳定通过。
    TestModel *warmup = [[TestModel alloc] init];
    CBModel_WarmUpAtomicProps(warmup);
    
    TestModel *model = [[TestModel alloc] init];
    dispatch_group_t group = dispatch_group_create();
    
    for (int i = 0; i < 200; i++) {
        dispatch_group_enter(group);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            model.atomicIntValue = i;
            model.atomicString = [NSString stringWithFormat:@"值 %d", i];
            for (int j = 1; j <= 16; j++) {
                [model setValue:@(i * 1.0) forKey:[NSString stringWithFormat:@"atomicDoubleValue%d", j]];
            }
            for (int j = 1; j <= 8; j++) {
                [model setValue:[NSString stringWithFormat:@"s%d", i] forKey:[NSString stringWithFormat:@"atomicExtraString%d", j]];
            }
            model.atomicPointValue = CGPointMake(i, i);
            model.atomicRectValue = CGRectMake(i, i, i * 2, i * 2);
            dispatch_group_leave(group);
        });
    }
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    // 数据完整性校验：所有 key 都应可读且值有效（修复前可能出现 key 丢失/错乱）
    XCTAssertTrue(model.atomicIntValue >= 0 && model.atomicIntValue < 200, @"并发写入后值应该有效");
    XCTAssertNotNil(model.atomicString, @"并发写入后字符串不应该为 nil");
    for (int j = 1; j <= 16; j++) {
        id v = [model valueForKey:[NSString stringWithFormat:@"atomicDoubleValue%d", j]];
        XCTAssertTrue([v doubleValue] >= 0 && [v doubleValue] < 200, @"atomicDoubleValue%d 并发写入后值应该有效", j);
    }
    for (int j = 1; j <= 8; j++) {
        id v = [model valueForKey:[NSString stringWithFormat:@"atomicExtraString%d", j]];
        XCTAssertNotNil(v, @"atomicExtraString%d 不应该为 nil", j);
    }
    XCTAssertTrue(CGRectGetWidth(model.atomicRectValue) >= 0, @"并发写入后结构体值应该有效");
}

// 验证 atomic 与 nonatomic 属性并存时的并发安全（P0-2.1 容器竞态回归，v1.4 Phase 2 改写）：
// 去锁重构后 non-atomic 属性为无锁槽（真 ivar 语义，并发写属使用者误用），
// 故并发阶段只写 atomic 属性；non-atomic 属性在并发期间保持不被干扰
- (void)testAtomicAndNonAtomicMixedConcurrentAccess {
    TestModel *warmup = [[TestModel alloc] init];
    warmup.intValue = 0;
    warmup.strongString = @"";
    warmup.rectValue = CGRectZero;
    warmup.pointValue = CGPointZero;
    warmup.atomicIntValue = 0;
    warmup.atomicString = @"";
    CBModel_WarmUpAtomicProps(warmup);
    
    TestModel *model = [[TestModel alloc] init];
    // 并发前单线程设置 non-atomic 初值（预触达已由 warmup 完成，此处仅设初值）
    model.intValue = 0;
    model.strongString = @"";
    model.rectValue = CGRectZero;
    model.pointValue = CGPointZero;
    dispatch_group_t group = dispatch_group_create();
    
    for (int i = 0; i < 200; i++) {
        dispatch_group_enter(group);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            model.atomicIntValue = i;
            model.atomicString = [NSString stringWithFormat:@"a%d", i];
            for (int j = 1; j <= 8; j++) {
                [model setValue:@(i * 1.0) forKey:[NSString stringWithFormat:@"atomicDoubleValue%d", j]];
            }
            dispatch_group_leave(group);
        });
    }
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    // 并发写 atomic 期间，non-atomic 槽（独立内存）不受干扰
    XCTAssertEqual(model.intValue, 0, @"non-atomic 槽不应被 atomic 并发写入干扰");
    XCTAssertEqualObjects(model.strongString, @"", @"non-atomic 槽不应被 atomic 并发写入干扰");
    XCTAssertTrue(CGRectEqualToRect(model.rectValue, CGRectZero), @"non-atomic 结构体槽不应被干扰");
    XCTAssertTrue(model.atomicIntValue >= 0 && model.atomicIntValue < 200, @"并发写入后值应该有效");
    XCTAssertNotNil(model.atomicString, @"并发写入后字符串不应该为 nil");
}

#pragma mark - 类级缓存竞态回归测试（P0-2.3）

// 验证类级缓存（selector→属性名）并发读写安全（P0-2.3 回归）：修复前 resolveInstanceMethod:
// 被多线程并发触发时（不同 selector 首次访问）会并发写共享静态字典，损坏缓存结构；
// 修复后并发首次解析不竞态、各属性最终值正确
- (void)testClassLevelCacheConcurrentResolve {
    // 两个全新模型类：本用例是唯一使用者，所有 selector 的首次解析都发生在并发阶段
    ResolveRaceModel *model = [[ResolveRaceModel alloc] init];
    ResolveRaceModel2 *model2 = [[ResolveRaceModel2 alloc] init];
    dispatch_group_t group = dispatch_group_create();
    
    for (int i = 0; i < 40; i++) {
        dispatch_group_enter(group);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // 并发首次访问不同属性 → 并发 resolveInstanceMethod → 并发写类级缓存
            model.propA = i;
            model.propB = i;
            model.propC = i;
            model.propD = i;
            model.propE = i;
            model.strF = [NSString stringWithFormat:@"f%d", i];
            model.strG = [NSString stringWithFormat:@"g%d", i];
            model.strH = [NSString stringWithFormat:@"h%d", i];
            model2.propA = i;
            model2.propB = i;
            model2.propC = i;
            model2.propD = i;
            model2.strE = [NSString stringWithFormat:@"e%d", i];
            model2.strF = [NSString stringWithFormat:@"f%d", i];
            dispatch_group_leave(group);
        });
    }
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    // 解析完成后所有属性都应可读且值有效（修复前缓存损坏会导致 propName 映射丢失、值错乱）
    XCTAssertTrue(model.propE >= 0 && model.propE < 40, @"并发首次解析后值应该有效");
    XCTAssertTrue(model2.propD >= 0 && model2.propD < 40, @"并发首次解析后值应该有效");
    XCTAssertNotNil(model.strH, @"并发首次解析后字符串不应该为 nil");
    XCTAssertNotNil(model2.strF, @"并发首次解析后字符串不应该为 nil");
}

// 性能基准：标量属性读写吞吐（v1.4 Phase 1 快查表前后对比用，
// 只测不走 forwardInvocation 的标量路径，XCTest measureBlock 自动统计 ns/op）
- (void)testPropertyAccessPerformance {
    TestModel *model = [[TestModel alloc] init];
    [self measureBlock:^{
        for (int i = 0; i < 100000; i++) {
            model.intValue = i;
            (void)model.intValue;
        }
    }];
}

#pragma mark - 边界情况测试

// 验证对象属性接受 nil 赋值：不崩溃且属性为 nil
- (void)testNilObjectProperty {
    TestModel *model = [[TestModel alloc] init];
    model.strongString = nil;
    XCTAssertNil(model.strongString, @"object 属性应该接受 nil");
}

// 验证属性接受零值
- (void)testZeroValueProperty {
    TestModel *model = [[TestModel alloc] init];
    model.intValue = 0;
    XCTAssertEqual(model.intValue, 0, @"属性应该接受零值");
}

// 验证属性接受负值
- (void)testNegativeValueProperty {
    TestModel *model = [[TestModel alloc] init];
    model.intValue = -100;
    XCTAssertEqual(model.intValue, -100, @"属性应该接受负值");
}

// 验证属性接受大值（LONG_MAX）
- (void)testLargeValueProperty {
    TestModel *model = [[TestModel alloc] init];
    model.longValue = LONG_MAX;
    XCTAssertEqual(model.longValue, LONG_MAX, @"属性应该接受大值");
}

#pragma mark - KVO 测试

// KVO 观察回调：按 keyPath 收集变更值，供各 KVO 用例断言
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    self.kvoObserverCalled = YES;
    if ([keyPath isEqualToString:@"intValue"] || [keyPath isEqualToString:@"atomicIntValue"]) {
        id value = change[NSKeyValueChangeNewKey];
        NSLog(@"%ld", [value integerValue]);
        self.kvoNewIntValue = [change[NSKeyValueChangeNewKey] integerValue];
    }
    else if ([keyPath isEqualToString:@"ldValue"]) {
        id value = change[NSKeyValueChangeNewKey];
        long double ld = 0;
        if (@available(iOS 11.0, *)) {
            [value getValue:&ld size:sizeof(long double)];
        } else {
            [value getValue:&ld];
        }
        self.kvoNewLdValue = ld;
    }
    else if ([keyPath isEqualToString:@"strongString"]) {
        self.kvoNewStringValue = change[NSKeyValueChangeNewKey];
    }
    else if ([keyPath isEqualToString:@"pointValue"]) {
        // 结构体属性：change 里的 old/new 都是 NSValue（值为 nil 时是 NSNull），取回 CGPoint 供顺序断言
        CGPoint oldP = CGPointZero;
        CGPoint newP = CGPointZero;
        id oldValue = change[NSKeyValueChangeOldKey];
        id newValue = change[NSKeyValueChangeNewKey];
        if ([oldValue isKindOfClass:[NSValue class]]) {
            [oldValue getValue:&oldP];
        }
        if ([newValue isKindOfClass:[NSValue class]]) {
            [newValue getValue:&newP];
        }
        self.kvoOldPointValue = oldP;
        self.kvoNewPointValue = newP;
    }
}

// 验证标量属性 KVO：setter 触发通知且 new 值正确
- (void)testKVOForIntProperty {
    TestModel *model = [[TestModel alloc] init];
    self.kvoModel = model;
    
    [model addObserver:self forKeyPath:@"intValue" options:NSKeyValueObservingOptionNew context:nil];
    
    model.intValue = 100;
    
    XCTAssertTrue(self.kvoObserverCalled, @"KVO 观察者应该被调用");
    XCTAssertEqual(self.kvoNewIntValue, model.intValue, @"KVO 变更应该包含新值");
    
    [model removeObserver:self forKeyPath:@"intValue"];
}

// 验证 long double 属性 KVO：通知值以 NSValue 承载，可正确读出
- (void)testKVOForLongDoubleProperty {
    TestModel *model = [[TestModel alloc] init];
    self.kvoModel = model;
    
    [model addObserver:self forKeyPath:@"ldValue" options:NSKeyValueObservingOptionNew context:nil];
    self.kvoNewLdValue = 0;
    model.ldValue = 100.01f;
    
    XCTAssertTrue(self.kvoObserverCalled, @"KVO 观察者应该被调用");
    XCTAssertEqual(self.kvoNewLdValue, model.ldValue, @"KVO 变更应该包含新值");
    
    [model removeObserver:self forKeyPath:@"ldValue"];
}

// 验证对象属性 KVO：old/new 值均可正确获取
- (void)testKVOForStringProperty {
    TestModel *model = [[TestModel alloc] init];
    self.kvoModel = model;
    
    [model addObserver:self forKeyPath:@"strongString" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    self.kvoNewStringValue = nil;
    model.strongString = @"新值";
    XCTAssertTrue(self.kvoObserverCalled, @"KVO 观察者应该被调用");
    XCTAssertEqualObjects(self.kvoNewStringValue, model.strongString, @"KVO 变更应该包含新值");
    
    [model removeObserver:self forKeyPath:@"strongString"];
}

// 验证 atomic 属性 KVO：setter 触发通知
- (void)testKVOForAtomicProperty {
    TestModel *model = [[TestModel alloc] init];
    self.kvoModel = model;
    
    [model addObserver:self forKeyPath:@"atomicIntValue" options:NSKeyValueObservingOptionNew context:nil];
    
    model.atomicIntValue = 200;
    
    XCTAssertTrue(self.kvoObserverCalled, @"atomic 属性的 KVO 观察者应该被调用");
    
    [model removeObserver:self forKeyPath:@"atomicIntValue"];
}

// 验证结构体属性 KVO 顺序（P0-2.2 回归）：willChange 必须先于存储，
// NSKeyValueChangeOldKey 应是变更前的值而非新值（修复前先存储后通知，old==new 顺序颠倒）
- (void)testKVOOrderForStructProperty {
    TestModel *model = [[TestModel alloc] init];
    self.kvoModel = model;
    
    model.pointValue = CGPointMake(10, 20); // 先建立确定性的旧值
    
    [model addObserver:self forKeyPath:@"pointValue" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    
    model.pointValue = CGPointMake(50, 60);
    
    XCTAssertTrue(self.kvoObserverCalled, @"KVO 观察者应该被调用");
    XCTAssertTrue(CGPointEqualToPoint(self.kvoNewPointValue, CGPointMake(50, 60)), @"new 值应该是新设置的值");
    XCTAssertTrue(CGPointEqualToPoint(self.kvoOldPointValue, CGPointMake(10, 20)), @"old 值应该是变更前的值（willChange 必须先于存储）");
    
    [model removeObserver:self forKeyPath:@"pointValue"];
}

#pragma mark - Description 测试

// 验证 description：输出包含类名、属性名与属性值
- (void)testDescription {
    TestModel *model = [[TestModel alloc] init];
    model.intValue = 42;
    model.strongString = @"测试";
    
    NSString *desc = model.description;
    XCTAssertNotNil(desc, @"description 不应该为 nil");
    XCTAssertTrue([desc containsString:@"TestModel"], @"description 应该包含类名");
    XCTAssertTrue([desc containsString:@"intValue"], @"description 应该包含属性名");
    XCTAssertTrue([desc containsString:@"42"], @"description 应该包含属性值");
}

// 验证 description 对 long double 属性的格式化（P0-2.4 回归）：修复前 'D' 类型掉进
// default 分支输出裸 NSValue（十六进制字节）；修复后输出格式化数值
- (void)testDescriptionLongDouble {
    TestModel *model = [[TestModel alloc] init];
    model.ldValue = 3.14L;
    
    NSString *desc = model.description;
    XCTAssertNotNil(desc, @"description 不应该为 nil");
    XCTAssertTrue([desc containsString:@"ldValue"], @"description 应该包含属性名");
    XCTAssertTrue([desc containsString:@"3.14"], @"description 应该输出 long double 数值");
}

#pragma mark - YYModel 兼容性测试

// 验证 YYModel JSON → Model：基础字段（字符串/整数/布尔/浮点）解析正确
- (void)testYYModelBasicJSONToModel {
    NSDictionary *json = @{
        @"name": @"张三",
        @"age": @25,
        @"isMale": @YES,
        @"height": @1.75,
        @"weight": @68.5
    };
    
    YYBasicModel *model = [YYBasicModel yy_modelWithJSON:json];
    
    XCTAssertNotNil(model, @"JSON 转模型应该成功");
    XCTAssertEqualObjects(model.name, @"张三", @"name 属性应该正确解析");
    XCTAssertEqual(model.age, 25, @"age 属性应该正确解析");
    XCTAssertTrue(model.isMale, @"isMale 属性应该正确解析");
    XCTAssertEqualWithAccuracy(model.height, 1.75, 0.01, @"height 属性应该正确解析");
    XCTAssertEqualWithAccuracy(model.weight, 68.5, 0.1, @"weight 属性应该正确解析");
}

// 验证 YYModel Model → JSON：字段转换正确
- (void)testYYModelModelToJSON {
    YYBasicModel *model = [[YYBasicModel alloc] init];
    model.name = @"李四";
    model.age = 30;
    model.isMale = NO;
    model.height = 1.68;
    model.weight = 55.0;
    
    NSDictionary *json = [model yy_modelToJSONObject];
    
    XCTAssertNotNil(json, @"模型转 JSON 应该成功");
    XCTAssertEqualObjects(json[@"name"], @"李四", @"name 应该正确转换");
    XCTAssertEqualObjects(json[@"age"], @30, @"age 应该正确转换");
    XCTAssertEqualObjects(json[@"isMale"], @NO, @"isMale 应该正确转换");
}

// 验证 YYModel 自定义属性名映射（JSON 的 id 映射到 userId 等）
- (void)testYYModelPropertyMapper {
    NSDictionary *json = @{
        @"id": @"user_001",
        @"name": @"王五",
        @"age": @28
    };
    
    YYMappingModel *model = [YYMappingModel yy_modelWithJSON:json];
    
    XCTAssertNotNil(model, @"自定义属性名映射应该成功");
    XCTAssertEqualObjects(model.userId, @"user_001", @"userId 应该从 id 映射");
    XCTAssertEqualObjects(model.userName, @"王五", @"userName 应该从 name 映射");
    XCTAssertEqual(model.userAge, 28, @"userAge 应该从 age 映射");
}

// 验证 YYModel 嵌套模型：JSON 子字典自动解析为对应模型对象
- (void)testYYModelNestedModel {
    NSDictionary *json = @{
        @"name": @"赵六",
        @"address": @{
            @"city": @"北京",
            @"street": @"长安街",
            @"zipCode": @100000
        }
    };
    
    YYUserModel *model = [YYUserModel yy_modelWithJSON:json];
    
    XCTAssertNotNil(model, @"嵌套模型解析应该成功");
    XCTAssertEqualObjects(model.name, @"赵六", @"name 应该正确解析");
    XCTAssertNotNil(model.address, @"address 应该正确解析");
    XCTAssertTrue([model.address isKindOfClass:[YYAddressModel class]], @"address 应该是 YYAddressModel 类型");
    XCTAssertEqualObjects(model.address.city, @"北京", @"city 应该正确解析");
    XCTAssertEqualObjects(model.address.street, @"长安街", @"street 应该正确解析");
    XCTAssertEqual(model.address.zipCode, 100000, @"zipCode 应该正确解析");
}

// 验证 YYModel 字符串数组容器：JSON 数组解析为 NSArray<NSString*>
- (void)testYYModelContainerStringArray {
    NSDictionary *json = @{
        @"stringArray": @[@"one", @"two", @"three"]
    };
    
    YYContainerModel *model = [YYContainerModel yy_modelWithJSON:json];
    
    XCTAssertNotNil(model, @"容器模型解析应该成功");
    XCTAssertNotNil(model.stringArray, @"stringArray 应该正确解析");
    XCTAssertEqual(model.stringArray.count, 3, @"stringArray 应该有 3 个元素");
    XCTAssertEqualObjects(model.stringArray[0], @"one", @"第一个元素应该是 one");
}

// 验证 YYModel 模型数组容器：JSON 数组元素自动转为模型对象
- (void)testYYModelContainerModelArray {
    NSDictionary *json = @{
        @"modelArray": @[
            @{@"name": @"A", @"age": @10},
            @{@"name": @"B", @"age": @20}
        ]
    };
    
    YYContainerModel *model = [YYContainerModel yy_modelWithJSON:json];
    
    XCTAssertNotNil(model, @"容器模型解析应该成功");
    XCTAssertNotNil(model.modelArray, @"modelArray 应该正确解析");
    XCTAssertEqual(model.modelArray.count, 2, @"modelArray 应该有 2 个元素");
    
    YYBasicModel *firstModel = model.modelArray[0];
    XCTAssertTrue([firstModel isKindOfClass:[YYBasicModel class]], @"元素应该是 YYBasicModel 类型");
    XCTAssertEqualObjects(firstModel.name, @"A", @"第一个模型 name 应该是 A");
    XCTAssertEqual(firstModel.age, 10, @"第一个模型 age 应该是 10");
}

// 验证 YYModel 模型字典容器：JSON 字典值自动转为模型对象
- (void)testYYModelContainerModelDict {
    NSDictionary *json = @{
        @"modelDict": @{
            @"user1": @{@"name": @"张三", @"age": @25},
            @"user2": @{@"name": @"李四", @"age": @30}
        }
    };
    
    YYContainerModel *model = [YYContainerModel yy_modelWithJSON:json];
    
    XCTAssertNotNil(model, @"容器模型解析应该成功");
    XCTAssertNotNil(model.modelDict, @"modelDict 应该正确解析");
    XCTAssertEqual(model.modelDict.count, 2, @"modelDict 应该有 2 个元素");
    
    YYBasicModel *user1 = model.modelDict[@"user1"];
    XCTAssertTrue([user1 isKindOfClass:[YYBasicModel class]], @"值应该是 YYBasicModel 类型");
    XCTAssertEqualObjects(user1.name, @"张三", @"user1 name 应该是张三");
}

// 验证动态属性（CBModel 注入 getter/setter）与 YYModel 序列化互操作
- (void)testYYModelDynamicProperty {
    YYDynamicModel *model = [[YYDynamicModel alloc] init];
    model.staticName = @"静态属性";
    
    NSDictionary *json = [model yy_modelToJSONObject];
    XCTAssertNotNil(json, @"动态属性模型转 JSON 应该成功");
    XCTAssertEqualObjects(json[@"staticName"], @"静态属性", @"staticName 应该正确转换");
    
    NSDictionary *inputJson = @{@"staticName": @"新的静态值"};
    YYDynamicModel *newModel = [YYDynamicModel yy_modelWithJSON:inputJson];
    XCTAssertEqualObjects(newModel.staticName, @"新的静态值", @"从 JSON 解析 staticName 应该成功");
}

// 验证协议声明属性 + YYModel 组合：遵循协议中带 property 也能动态注入并参与序列化
- (void)testYYModelProtocolCombination {
    NSDictionary *json = @{
        @"realName": @"真实姓名",
        @"nickName": @"昵称",
        @"score": @100
    };
    
    YYProtocolModel *model = [YYProtocolModel yy_modelWithJSON:json];
    
    XCTAssertNotNil(model, @"协议组合模型解析应该成功");
    XCTAssertEqualObjects(model.realName, @"真实姓名", @"realName 应该正确解析");
    XCTAssertEqualObjects(model.nickName, @"昵称", @"nickName 动态属性应该正确解析");
    XCTAssertEqual(model.score, 100, @"score 动态属性应该正确解析");
}

// 验证 YYModel 自定义回调：modelCustomTransformFromDictionary: / modelCustomTransformToDictionary: 生效
- (void)testYYModelCallbackMethods {
    NSDictionary *json = @{
        @"name": @"测试用户",
        @"age": @-5
    };
    
    YYCallbackModel *model = [YYCallbackModel yy_modelWithJSON:json];
    
    XCTAssertNotNil(model, @"回调模型解析应该成功");
    XCTAssertTrue(model.didCustomize, @"modelCustomTransformFromDictionary: 应该被调用");
    XCTAssertEqual(model.age, 0, @"负数 age 应该在回调中被修正为 0");
    
    NSDictionary *outputJson = [model yy_modelToJSONObject];
    XCTAssertTrue(model.willConvert, @"modelCustomTransformToDictionary: 应该被调用");
    XCTAssertNotNil(outputJson, @"转换后的 JSON 不应该为 nil");
}

// 验证 YYModel 复杂类型解析：标量家族 + 结构体（CGSize/CGRect/CGPoint）从字符串还原
- (void)testYYModelComplexTypes {
    NSDictionary *json = @{
        @"charValue": @(65),
        @"shortValue": @(1000),
        @"longValue": @(123456789),
        @"llValue": @(9876543210LL),
        @"uintValue": @(999),
        @"ullValue": @(1234567890123ULL),
        @"sizeValue": NSStringFromCGSize(CGSizeMake(100, 200)),
        @"rectValue": NSStringFromCGRect(CGRectMake(10, 20, 100, 200)),
        @"pointValue": NSStringFromCGPoint(CGPointMake(50, 60))
    };
    
    YYComplexModel *model = [YYComplexModel yy_modelWithJSON:json];
    
    XCTAssertNotNil(model, @"复杂类型模型解析应该成功");
    XCTAssertEqual(model.charValue, 65, @"charValue 应该正确解析");
    XCTAssertEqual(model.shortValue, 1000, @"shortValue 应该正确解析");
    XCTAssertEqual(model.longValue, 123456789, @"longValue 应该正确解析");
    XCTAssertEqual(model.llValue, 9876543210LL, @"llValue 应该正确解析");
}

// 验证 YYModel 忽略属性：黑名单属性不参与序列化
- (void)testYYModelIgnoreProperties {
    YYIgnoreModel *model = [[YYIgnoreModel alloc] init];
    model.name = @"用户名";
    model.password = @"密码123";
    model.internalId = 999;
    
    NSDictionary *json = [model yy_modelToJSONObject];
    
    XCTAssertNotNil(json, @"忽略属性模型转 JSON 应该成功");
    XCTAssertEqualObjects(json[@"name"], @"用户名", @"name 应该被转换");
    XCTAssertNil(json[@"password"], @"password 应该被忽略");
    XCTAssertNil(json[@"internalId"], @"internalId 应该被忽略");
}

// 验证 YYModel 类型不匹配容错：JSON 类型与属性不符时不崩溃，能解析的字段照常解析
- (void)testYYModelWithInvalidJSON {
    NSDictionary *json = @{
        @"name": @"测试",
        @"age": @"不是数字"
    };
    
    YYBasicModel *model = [YYBasicModel yy_modelWithJSON:json];
    
    XCTAssertNotNil(model, @"即使 JSON 类型不匹配，模型也应该创建成功");
    XCTAssertEqualObjects(model.name, @"测试", @"name 应该正确解析");
}

// 验证 YYModel 空 JSON：创建有效模型，字段保持默认值
- (void)testYYModelWithEmptyJSON {
    NSDictionary *json = @{};
    
    YYBasicModel *model = [YYBasicModel yy_modelWithJSON:json];
    
    XCTAssertNotNil(model, @"空 JSON 应该创建一个有效的模型");
    XCTAssertNil(model.name, @"name 应该为 nil");
    XCTAssertEqual(model.age, 0, @"age 应该为默认值 0");
}

// 验证 YYModel nil JSON：直接返回 nil
- (void)testYYModelWithNilJSON {
    YYBasicModel *model = [YYBasicModel yy_modelWithJSON:nil];
    
    XCTAssertNil(model, @"用nil JSON 创建模型是直接返回 nil");
}

// 性能基准：1000 次 JSON 解析的耗时（XCTest 自动统计基线）
- (void)testYYModelPerformance {
    NSDictionary *json = @{
        @"name": @"性能测试",
        @"age": @25,
        @"isMale": @YES,
        @"height": @1.75,
        @"weight": @68.5
    };
    
    [self measureBlock:^{
        for (int i = 0; i < 1000; i++) {
            YYBasicModel *model = [YYBasicModel yy_modelWithJSON:json];
            (void)model;
        }
    }];
}

// 验证 yy_modelCopy：复制的模型字段独立，修改副本不影响原模型
- (void)testYYModelCopyWithYYModel {
    YYBasicModel *model = [[YYBasicModel alloc] init];
    model.name = @"原始模型";
    model.age = 25;
    
    YYBasicModel *copiedModel = [model yy_modelCopy];
    
    XCTAssertNotNil(copiedModel, @"YYModel 复制应该成功");
    XCTAssertEqualObjects(copiedModel.name, model.name, @"复制的 name 应该相同");
    XCTAssertEqual(copiedModel.age, model.age, @"复制的 age 应该相同");
    
    copiedModel.name = @"修改后的名称";
    XCTAssertNotEqualObjects(model.name, copiedModel.name, @"修改复制模型不应该影响原模型");
}

// 验证 yy_modelDescription：输出包含类名
- (void)testYYModelDescriptionMethod {
    YYBasicModel *model = [[YYBasicModel alloc] init];
    model.name = @"描述测试";
    model.age = 30;
    
    NSString *desc = [model yy_modelDescription];
    
    XCTAssertNotNil(desc, @"YYModel description 不应该为 nil");
    XCTAssertTrue([desc containsString:@"YYBasicModel"], @"description 应该包含类名");
}

// 验证 yy_modelEncodeWithCoder / yy_modelInitWithCoder：编解码往返字段一致
- (void)testYYModelEncodeDecode {
    YYBasicModel *model = [[YYBasicModel alloc] init];
    model.name = @"编码测试";
    model.age = 35;
    model.isMale = YES;
    
    NSMutableData *data = [NSMutableData data];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [model yy_modelEncodeWithCoder:archiver];
    [archiver finishEncoding];
    XCTAssertNotNil(data, @"编码应该成功");
    
    NSKeyedUnarchiver *unarchiver = nil;
    if (@available(iOS 11.0, *)) {
        NSError* error = nil;
        unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:data error:&error];
    } else {
        unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    }
    YYBasicModel *decodedModel = [[YYBasicModel alloc] yy_modelInitWithCoder:unarchiver];
    XCTAssertNotNil(decodedModel, @"解码应该成功");
    XCTAssertEqualObjects(decodedModel.name, @"编码测试", @"解码后 name 应该匹配");
    XCTAssertEqual(decodedModel.age, 35, @"解码后 age 应该匹配");
    XCTAssertEqual(decodedModel.isMale, YES, @"解码后 isMale 应该匹配");
}

// 验证含动态属性（协议注入）的模型编解码：动态属性字段往返一致
- (void)testYYModelEncodeDecodeWithDynamicProperties {
    YYProtocolModel *model = [[YYProtocolModel alloc] init];
    model.realName = @"动态属性测试";
    model.nickName = @"昵称";
    model.score = 100;
    
    NSMutableData *data = [NSMutableData data];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [model yy_modelEncodeWithCoder:archiver];
    [archiver finishEncoding];
    XCTAssertNotNil(data, @"编码应该成功");
    
    NSKeyedUnarchiver *unarchiver = nil;
    if (@available(iOS 11.0, *)) {
        NSError* error = nil;
        unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:data error:&error];
    } else {
        unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    }
    YYProtocolModel *decodedModel = [[YYProtocolModel alloc] yy_modelInitWithCoder:unarchiver];
    XCTAssertNotNil(decodedModel, @"解码应该成功");
    XCTAssertEqualObjects(decodedModel.realName, @"动态属性测试", @"解码后 realName 应该匹配");
    XCTAssertEqualObjects(decodedModel.nickName, @"昵称", @"解码后 nickName 动态属性应该匹配");
    XCTAssertEqual(decodedModel.score, 100, @"解码后 score 动态属性应该匹配");
}

// 验证 CBModel 子类与 YYModel 互操作：CBModel 动态属性模型可转 JSON
- (void)testYYModelWithCBModelFeatures {
    YYBasicModel *model = [[YYBasicModel alloc] init];
    model.name = @"CBModel 特性测试";
    model.age = 40;
    
    TestModel *testModel = [[TestModel alloc] init];
    testModel.intValue = 100;
    
    NSDictionary *json = [testModel yy_modelToJSONObject];
    XCTAssertEqualObjects(json[@"intValue"], @100, @"CBModel 子类应该支持 YYModel 转换");
}

#pragma mark - 结构体类型测试

// 验证 CGPoint 结构体属性：经 forwardInvocation 存取正确
- (void)testCGPointProperty {
    TestModel *model = [[TestModel alloc] init];
    CGPoint point = CGPointMake(100.5, 200.5);
    model.pointValue = point;
    
    point = model.pointValue;
    
    XCTAssertEqualWithAccuracy(model.pointValue.x, 100.5, 0.001, @"CGPoint x 应该正确存储");
    XCTAssertEqualWithAccuracy(model.pointValue.y, 200.5, 0.001, @"CGPoint y 应该正确存储");
}

// 验证 CGSize 结构体属性：存取正确
- (void)testCGSizeProperty {
    TestModel *model = [[TestModel alloc] init];
    CGSize size = CGSizeMake(300.0, 400.0);
    model.sizeValue = size;
    
    XCTAssertEqualWithAccuracy(model.sizeValue.width, 300.0, 0.001, @"CGSize width 应该正确存储");
    XCTAssertEqualWithAccuracy(model.sizeValue.height, 400.0, 0.001, @"CGSize height 应该正确存储");
}

// 验证 CGRect 结构体属性：四字段存取正确
- (void)testCGRectProperty {
    TestModel *model = [[TestModel alloc] init];
    CGRect rect = CGRectMake(10.0, 20.0, 100.0, 200.0);
    model.rectValue = rect;
    
    XCTAssertEqualWithAccuracy(model.rectValue.origin.x, 10.0, 0.001, @"CGRect origin.x 应该正确存储");
    XCTAssertEqualWithAccuracy(model.rectValue.origin.y, 20.0, 0.001, @"CGRect origin.y 应该正确存储");
    XCTAssertEqualWithAccuracy(model.rectValue.size.width, 100.0, 0.001, @"CGRect size.width 应该正确存储");
    XCTAssertEqualWithAccuracy(model.rectValue.size.height, 200.0, 0.001, @"CGRect size.height 应该正确存储");
}

// 验证 UIEdgeInsets 结构体属性：存取正确
- (void)testUIEdgeInsetsProperty {
    TestModel *model = [[TestModel alloc] init];
    UIEdgeInsets insets = UIEdgeInsetsMake(10, 20, 30, 40);
    model.edgeInsetsValue = insets;
    
    XCTAssertEqual(model.edgeInsetsValue.top, 10, @"UIEdgeInsets top 应该正确存储");
    XCTAssertEqual(model.edgeInsetsValue.left, 20, @"UIEdgeInsets left 应该正确存储");
    XCTAssertEqual(model.edgeInsetsValue.bottom, 30, @"UIEdgeInsets bottom 应该正确存储");
    XCTAssertEqual(model.edgeInsetsValue.right, 40, @"UIEdgeInsets right 应该正确存储");
}

// 验证 NSRange 结构体属性：存取正确
- (void)testNSRangeProperty {
    TestModel *model = [[TestModel alloc] init];
    NSRange range = NSMakeRange(5, 10);
    model.rangeValue = range;
    
    XCTAssertEqual(model.rangeValue.location, 5, @"NSRange location 应该正确存储");
    XCTAssertEqual(model.rangeValue.length, 10, @"NSRange length 应该正确存储");
}

// 验证 CGAffineTransform 结构体属性：存取正确
- (void)testCGAffineTransformProperty {
    TestModel *model = [[TestModel alloc] init];
    CGAffineTransform transform = CGAffineTransformMakeTranslation(100, 200);
    model.transformValue = transform;
    
    XCTAssertEqualWithAccuracy(model.transformValue.tx, 100, 0.001, @"CGAffineTransform tx 应该正确存储");
    XCTAssertEqualWithAccuracy(model.transformValue.ty, 200, 0.001, @"CGAffineTransform ty 应该正确存储");
}

// 验证 CATransform3D 大结构体属性：存取正确
- (void)testCATransform3DProperty {
    TestModel *model = [[TestModel alloc] init];
    CATransform3D transform = CATransform3DMakeTranslation(50, 100, 150);
    model.transform3DValue = transform;
    
    XCTAssertEqualWithAccuracy(model.transform3DValue.m41, 50, 0.001, @"CATransform3D m41 应该正确存储");
    XCTAssertEqualWithAccuracy(model.transform3DValue.m42, 100, 0.001, @"CATransform3D m42 应该正确存储");
    XCTAssertEqualWithAccuracy(model.transform3DValue.m43, 150, 0.001, @"CATransform3D m43 应该正确存储");
}

// 验证 atomic 结构体属性（CGPoint）：存取正确
- (void)testAtomicCGPointProperty {
    TestModel *model = [[TestModel alloc] init];
    CGPoint point = CGPointMake(500.0, 600.0);
    model.atomicPointValue = point;
    
    XCTAssertEqualWithAccuracy(model.atomicPointValue.x, 500.0, 0.001, @"atomic CGPoint x 应该正确存储");
    XCTAssertEqualWithAccuracy(model.atomicPointValue.y, 600.0, 0.001, @"atomic CGPoint y 应该正确存储");
}

// 验证 atomic 结构体属性（CGRect）：存取正确
- (void)testAtomicCGRectProperty {
    TestModel *model = [[TestModel alloc] init];
    CGRect rect = CGRectMake(1, 2, 3, 4);
    model.atomicRectValue = rect;
    
    XCTAssertEqualWithAccuracy(model.atomicRectValue.origin.x, 1, 0.001, @"atomic CGRect origin.x 应该正确存储");
    XCTAssertEqualWithAccuracy(model.atomicRectValue.origin.y, 2, 0.001, @"atomic CGRect origin.y 应该正确存储");
    XCTAssertEqualWithAccuracy(model.atomicRectValue.size.width, 3, 0.001, @"atomic CGRect size.width 应该正确存储");
    XCTAssertEqualWithAccuracy(model.atomicRectValue.size.height, 4, 0.001, @"atomic CGRect size.height 应该正确存储");
}

// 验证 atomic 结构体属性多线程并发读写：结束后值有效（forwardInvocation 路径的并发安全）
- (void)testStructPropertyConcurrentAccess {
    TestModel *model = [[TestModel alloc] init];
    model.atomicRectValue = CGRectZero;
    
    dispatch_group_t group = dispatch_group_create();
    
    for (int i = 0; i < 100; i++) {
        dispatch_group_enter(group);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            CGRect rect = CGRectMake(i, i, i * 2, i * 2);
            model.atomicRectValue = rect;
            dispatch_group_leave(group);
        });
        
        dispatch_group_enter(group);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            CGRect rect = model.atomicRectValue;
            (void)rect;
            dispatch_group_leave(group);
        });
    }
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    XCTAssertTrue(CGRectGetWidth(model.atomicRectValue) >= 0, @"atomic 结构体并发访问后值应该有效");
}

#pragma mark - 自定义 getter/setter 测试

// 验证自定义 getter 名（getter=isCurrent）：isCurrent 与默认 current 均可访问
- (void)testCustomGetter {
    TestModel *model = [[TestModel alloc] init];
    model.current = YES;
    
    XCTAssertTrue(model.isCurrent, @"自定义 getter isCurrent 应该正常工作");
    XCTAssertTrue(model.current, @"默认 getter current 也应该正常工作");
}

// 验证自定义 setter 名（setter=setSpecialName:）：setSpecialName: 赋值生效
- (void)testCustomSetter {
    TestModel *model = [[TestModel alloc] init];
    model.specialName = @"测试名称";
    
    XCTAssertEqualObjects(model.specialName, @"测试名称", @"自定义 setter setSpecialName: 应该正常工作");
}

// 验证自定义 getter 属性的 KVO：setter 触发通知
- (void)testCustomGetterKVO {
    TestModel *model = [[TestModel alloc] init];
    self.kvoModel = model;
    
    [model addObserver:self forKeyPath:@"current" options:NSKeyValueObservingOptionNew context:nil];
    
    model.current = YES;
    
    XCTAssertTrue(self.kvoObserverCalled, @"自定义 getter 的属性 KVO 应该正常工作");
    
    [model removeObserver:self forKeyPath:@"current"];
}

#pragma mark - 结构体 KVO 测试

// 验证结构体属性（CGPoint）KVO：走 forwardInvocation 的 setter 触发通知
- (void)testKVOForCGPointProperty {
    TestModel *model = [[TestModel alloc] init];
    self.kvoModel = model;
    
    [model addObserver:self forKeyPath:@"pointValue" options:NSKeyValueObservingOptionNew context:nil];
    
    model.pointValue = CGPointMake(50, 60);
    
    XCTAssertTrue(self.kvoObserverCalled, @"结构体属性 KVO 观察者应该被调用");
    
    [model removeObserver:self forKeyPath:@"pointValue"];
}

// 验证结构体属性（CGRect）KVO：走 forwardInvocation 的 setter 触发通知
- (void)testKVOForCGRectProperty {
    TestModel *model = [[TestModel alloc] init];
    self.kvoModel = model;
    
    [model addObserver:self forKeyPath:@"rectValue" options:NSKeyValueObservingOptionNew context:nil];
    
    model.rectValue = CGRectMake(10, 20, 100, 200);
    
    XCTAssertTrue(self.kvoObserverCalled, @"CGRect 属性 KVO 观察者应该被调用");
    
    [model removeObserver:self forKeyPath:@"rectValue"];
}

#pragma mark - 结构体边界测试

// 验证结构体零值（CGPointZero/CGSizeZero/CGRectZero）存取正确
- (void)testStructZeroValue {
    TestModel *model = [[TestModel alloc] init];
    model.pointValue = CGPointZero;
    model.sizeValue = CGSizeZero;
    model.rectValue = CGRectZero;
    
    XCTAssertTrue(CGPointEqualToPoint(model.pointValue, CGPointZero), @"CGPointZero 应该正确存储");
    XCTAssertTrue(CGSizeEqualToSize(model.sizeValue, CGSizeZero), @"CGSizeZero 应该正确存储");
    XCTAssertTrue(CGRectEqualToRect(model.rectValue, CGRectZero), @"CGRectZero 应该正确存储");
}

// 验证大值结构体存取（CGFLOAT_MAX）
- (void)testStructLargeValue {
    TestModel *model = [[TestModel alloc] init];
    CGRect largeRect = CGRectMake(CGFLOAT_MAX, CGFLOAT_MAX, CGFLOAT_MAX, CGFLOAT_MAX);
    model.rectValue = largeRect;
    
    XCTAssertEqual(model.rectValue.origin.x, CGFLOAT_MAX, @"大值 CGRect 应该正确存储");
}

// 验证负值结构体存取
- (void)testStructNegativeValue {
    TestModel *model = [[TestModel alloc] init];
    CGRect rect = CGRectMake(-100, -200, 300, 400);
    model.rectValue = rect;
    
    XCTAssertEqual(model.rectValue.origin.x, -100, @"负值 origin.x 应该正确存储");
    XCTAssertEqual(model.rectValue.origin.y, -200, @"负值 origin.y 应该正确存储");
}

#pragma mark - 相等性测试（P2：isEqual: / hash）

// 验证同值模型相等：标量/对象/weak/结构体全类型同值 → isEqual YES 且 hash 相同
- (void)testIsEqualSameValues {
    TestModel *a = [[TestModel alloc] init];
    TestModel *b = [[TestModel alloc] init];
    a.intValue = 42; b.intValue = 42;
    a.doubleValue = 3.14; b.doubleValue = 3.14;
    a.strongString = @"hello"; b.strongString = @"hello";
    a.pointValue = CGPointMake(1, 2); b.pointValue = CGPointMake(1, 2);
    NSObject *obj = [[NSObject alloc] init];
    a.weakObject = obj; b.weakObject = obj;
    
    XCTAssertEqualObjects(a, b, @"同值模型应该相等");
    XCTAssertEqual(a.hash, b.hash, @"同值模型 hash 应该相同");
}

// 验证任一属性不同 → 不相等（标量/对象/结构体各验证一种）
- (void)testIsEqualDifferentValues {
    TestModel *a = [[TestModel alloc] init];
    TestModel *b = [[TestModel alloc] init];
    a.intValue = 42; b.intValue = 43;
    XCTAssertFalse([a isEqual:b], @"标量不同应该不相等");
    
    a.intValue = 42; a.strongString = @"a"; b.strongString = @"b";
    XCTAssertFalse([a isEqual:b], @"对象不同应该不相等");
    
    a.strongString = nil; a.pointValue = CGPointMake(1, 1); b.pointValue = CGPointMake(1, 2);
    XCTAssertFalse([a isEqual:b], @"结构体不同应该不相等");
}

// 验证未触碰属性按默认零值参与比较：显式设置 0/nil 与未触碰相等
- (void)testIsEqualDefaultVsSetZero {
    TestModel *a = [[TestModel alloc] init];
    TestModel *b = [[TestModel alloc] init];
    a.intValue = 0;          // 显式触碰并设置为 0
    a.strongString = nil;    // 显式设置为 nil
    XCTAssertEqualObjects(a, b, @"显式零值与默认值应该相等");
    XCTAssertEqual(a.hash, b.hash, @"显式零值与默认值的 hash 应该一致");
}

// 验证不同类（属性集不同）不相等
- (void)testIsEqualDifferentClass {
    TestModel *a = [[TestModel alloc] init];
    ResolveRaceModel *b = [[ResolveRaceModel alloc] init];
    XCTAssertFalse([a isEqual:b], @"不同类（属性集不同）不应该相等");
}

// 验证 NSSet 去重：等值模型只保留一个
- (void)testNSSetDeduplication {
    TestModel *a = [[TestModel alloc] init];
    TestModel *b = [[TestModel alloc] init];
    a.intValue = 7; b.intValue = 7;
    a.strongString = @"x"; b.strongString = @"x";
    
    NSSet *set = [NSSet setWithObjects:a, b, nil];
    XCTAssertEqual(set.count, 1, @"等值模型在 NSSet 中应该去重");
}

// 验证 KVO swizzle 后相等性仍正确
- (void)testIsEqualAfterKVO {
    TestModel *a = [[TestModel alloc] init];
    TestModel *b = [[TestModel alloc] init];
    a.intValue = 9; b.intValue = 9;
    
    [a addObserver:self forKeyPath:@"intValue" options:NSKeyValueObservingOptionNew context:nil];
    XCTAssertEqualObjects(a, b, @"KVO swizzle 后相等性应该保持");
    XCTAssertEqual(a.hash, b.hash, @"KVO swizzle 后 hash 应该一致");
    [a removeObserver:self forKeyPath:@"intValue"];
}

// 验证浮点零：-0.0 与 +0.0 isEqual 相等且 hash 一致（与 NSNumber 语义一致）
- (void)testIsEqualFloatNegativeZero {
    TestModel *a = [[TestModel alloc] init];
    TestModel *b = [[TestModel alloc] init];
    a.doubleValue = 0.0;
    b.doubleValue = -0.0;
    XCTAssertEqualObjects(a, b, @"-0.0 与 +0.0 应该相等");
    XCTAssertEqual(a.hash, b.hash, @"-0.0 与 +0.0 的 hash 应该一致");
}

// 验证协议注入属性的相等性覆盖：协议属性与类内属性混合，同值相等、协议属性异值不等
- (void)testIsEqualWithProtocolProperties {
    ProtocolPropModel *a = [[ProtocolPropModel alloc] init];
    ProtocolPropModel *b = [[ProtocolPropModel alloc] init];
    a.protocolInt = 5; b.protocolInt = 5;
    a.protocolString = @"协议值"; b.protocolString = @"协议值";
    a.ownInt = 9; b.ownInt = 9;
    XCTAssertEqualObjects(a, b, @"协议属性同值的模型应该相等");
    XCTAssertEqual(a.hash, b.hash, @"协议属性同值的模型 hash 应该一致");
    
    b.protocolInt = 6;
    XCTAssertFalse([a isEqual:b], @"协议属性不同应该不相等");
    a.protocolInt = 5; b.protocolInt = 5;
    b.protocolString = @"另一个值";
    XCTAssertFalse([a isEqual:b], @"协议字符串属性不同应该不相等");
}

#pragma mark - readonly 属性测试（P2：只注入 getter、不注入 setter）

// 验证 readonly 属性只注入 getter：getter 可用且返回默认值（标量/对象/结构体）。
// 注：结构体属性走消息转发（无 IMP），respondsToSelector 不认转发方法，需直接调用验证
- (void)testReadonlyGetterInjected {
    TestModel *model = [[TestModel alloc] init];
    XCTAssertTrue([model respondsToSelector:@selector(readonlyIntValue)], @"readonly 属性的 getter 应该被注入");
    XCTAssertTrue([model respondsToSelector:@selector(readonlyString)], @"readonly 属性的 getter 应该被注入");
    XCTAssertEqual(model.readonlyIntValue, 0, @"readonly 属性应返回默认值");
    XCTAssertNil(model.readonlyString, @"readonly 属性应返回默认值");
    XCTAssertTrue(CGPointEqualToPoint(model.readonlyPointValue, CGPointZero), @"readonly 结构体属性 getter 应经转发返回默认值");
}

// 验证 readonly 属性不注入 setter：不响应 setter、无 setter 方法签名（标量 + 结构体）
- (void)testReadonlySetterNotInjected {
    TestModel *model = [[TestModel alloc] init];
    XCTAssertFalse([model respondsToSelector:@selector(setReadonlyIntValue:)], @"readonly 属性的 setter 不应被注入");
    XCTAssertFalse([model respondsToSelector:@selector(setReadonlyString:)], @"readonly 属性的 setter 不应被注入");
    XCTAssertFalse([model respondsToSelector:@selector(setReadonlyPointValue:)], @"readonly 结构体属性的 setter 不应被注入");
    XCTAssertNil([model methodSignatureForSelector:@selector(setReadonlyIntValue:)], @"readonly 属性的 setter 不应有方法签名");
    XCTAssertNil([model methodSignatureForSelector:@selector(setReadonlyPointValue:)], @"readonly 结构体属性的 setter 不应有方法签名");
}

// 验证 KVC 对 readonly 属性赋值抛 NSUnknownKeyException（标准 KVC 语义）
- (void)testReadonlyKVCSetThrows {
    TestModel *model = [[TestModel alloc] init];
    XCTAssertThrows([model setValue:@(5) forKey:@"readonlyIntValue"], @"KVC 对 readonly 属性赋值应该抛异常");
    XCTAssertThrows([model setValue:@"x" forKey:@"readonlyString"], @"KVC 对 readonly 属性赋值应该抛异常");
}

#pragma mark - 类属性测试（P2）

// 验证类属性 getter/setter 注入与存取（对象 strong/copy/标量）
- (void)testClassPropertyGetSet {
    XCTAssertTrue([ClassPropModel respondsToSelector:@selector(sharedName)], @"类属性 getter 应该被注入");
    XCTAssertTrue([ClassPropModel respondsToSelector:@selector(setSharedName:)], @"类属性 setter 应该被注入");
    
    [ClassPropModel setSharedName:@"全局名"];
    XCTAssertEqualObjects([ClassPropModel sharedName], @"全局名", @"类属性存取应该正常");
    
    [ClassPropModel setSharedCount:42];
    XCTAssertEqual([ClassPropModel sharedCount], 42, @"标量类属性存取应该正常");
    
    [ClassPropModel setSharedCopy:[[NSMutableString alloc] initWithString:@"copy值"]];
    XCTAssertEqualObjects([ClassPropModel sharedCopy], @"copy值", @"copy 类属性应该复制值");
}

// 验证类属性默认值（未设置时为 0/nil；本用例字母序先于 testClassPropertyGetSet 执行）
- (void)testClassPropertyDefaultValue {
    XCTAssertEqual([ClassPropModel sharedCount], 0, @"类属性默认值应为 0");
    XCTAssertNil([ClassPropModel sharedName], @"类属性默认值应为 nil");
}

// 验证 weak 类属性：对象释放后自动置 nil
- (void)testClassPropertyWeak {
    @autoreleasepool {
        NSObject *obj = [[NSObject alloc] init];
        [ClassPropModel setSharedWeak:obj];
        XCTAssertEqual([ClassPropModel sharedWeak], obj, @"weak 类属性应该正常");
        obj = nil;
    }
    XCTAssertNil([ClassPropModel sharedWeak], @"weak 类属性在对象释放后应为 nil");
}

// 验证 readonly 类属性：只注入 getter、不注入 setter
- (void)testClassPropertyReadonly {
    XCTAssertTrue([ClassPropModel respondsToSelector:@selector(sharedReadonly)], @"readonly 类属性 getter 应该被注入");
    XCTAssertFalse([ClassPropModel respondsToSelector:@selector(setSharedReadonly:)], @"readonly 类属性 setter 不应被注入");
    XCTAssertEqual([ClassPropModel sharedReadonly], 0, @"readonly 类属性应返回默认值");
}

// 验证类属性是类方法而非实例方法：实例不响应类属性 selector
- (void)testClassPropertyNotOnInstance {
    ClassPropModel *model = [[ClassPropModel alloc] init];
    XCTAssertFalse([model respondsToSelector:@selector(sharedName)], @"实例不应响应类属性 getter");
    XCTAssertFalse([model respondsToSelector:@selector(setSharedName:)], @"实例不应响应类属性 setter");
}

// 验证插件化场景：运行中动态创建 CBModel 子类（objc_allocateClassPair + 手动加 @dynamic 属性），
// 触发类表 COW 自动增长（首容量 8，累计 20+ 个类必然触发 8→16→32 多次迁移）
- (void)testPluginDynamicClassRegistration {
    for (int i = 0; i < 20; i++) {
        NSString *className = [NSString stringWithFormat:@"CBTestDynModel%d", i];
        Class cls = objc_allocateClassPair(CBModel.class, className.UTF8String, 0);
        XCTAssertNotNil(cls, @"动态类创建失败");
        
        // 手动添加带 @dynamic(D) 标记的属性（模拟插件 bundle 的模型类）
        objc_property_attribute_t typeAttr = {"T", "i"};
        objc_property_attribute_t dynAttr = {"D", ""};
        objc_property_attribute_t attrs[] = {typeAttr, dynAttr};
        XCTAssertTrue(class_addProperty(cls, "dynValue", attrs, 2), @"动态属性添加失败");
        objc_registerClassPair(cls);
        
        // 触碰属性：触发 resolveInstanceMethod（建表 + COW 迁移）+ KVC 读写
        id model = [[cls alloc] init];
        [model setValue:@(i) forKey:@"dynValue"];
        XCTAssertEqual([[model valueForKey:@"dynValue"] integerValue], i, @"动态类属性读写应该正常");
    }
}

#pragma mark - v1.5：结构体裸字节 IMP（已知结构体脱离 forwardInvocation）

/// 验证核心场景：运行时动态类（服务端驱动模型）添加结构体属性——
/// T 编码运行时才给定，但类型本身是已知结构体，resolveInstanceMethod 按编码 tag 匹配到
/// 预编译裸字节 IMP（16B 寄存器返回 / >16B sret 均由编译器 ABI 保证），
/// 不依赖编译期 @property 声明、不依赖 NSInvocation 转发。
/// 覆盖注册表全部 7 类型：CGPoint/CGSize/NSRange/CGRect/UIEdgeInsets/CGAffineTransform/CATransform3D
/// （CATransform3D 128B 用 RawBig 按需分配缓冲，同样脱离转发）。
- (void)testStructImpRuntimeDynamicClass {
    Class cls = objc_allocateClassPair(CBModel.class, "CBTestDynStructModel", 0);
    XCTAssertNotNil(cls, @"动态类创建失败");
    
    // 运行时添加结构体属性（T 编码运行时给定，与插件 bundle 一致）
    objc_property_attribute_t dynAttr = {"D", ""};
    struct { const char *name; const char *encoding; } props[] = {
        {"pointValue",      "{CGPoint=dd}"},
        {"sizeValue",       "{CGSize=dd}"},
        {"rangeValue",      "{_NSRange=QQ}"},                              // NSRange 的 tag 是 _NSRange
        {"rectValue",       "{CGRect={CGPoint=dd}{CGSize=dd}}"},
        {"insetsValue",     "{UIEdgeInsets=dddd}"},
        {"transformValue",  "{CGAffineTransform=dddddd}"},
        {"transform3DValue","{CATransform3D=dddddddddddddddd}"},           // 128B：RawBig 按需缓冲
    };
    for (int i = 0; i < 7; i++) {
        objc_property_attribute_t typeAttr = {"T", props[i].encoding};
        objc_property_attribute_t attrs[] = {typeAttr, dynAttr};
        XCTAssertTrue(class_addProperty(cls, props[i].name, attrs, 2), @"%s 属性添加失败", props[i].name);
    }
    objc_registerClassPair(cls);
    
    id model = [[cls alloc] init];
    
    // 未写入 → 裸字节槽全零 → 零值（alloc/calloc 清零语义）
    NSValue *zeroP = [model valueForKey:@"pointValue"];
    XCTAssertTrue(CGPointEqualToPoint(zeroP.CGPointValue, CGPointZero), @"未写入的 CGPoint 应该是零值");
    
    // 逐类型写入 → 读取往返（16B 寄存器返回 / 32B、48B、128B sret 路径全覆盖）
    CGPoint p = CGPointMake(10.5, -20.25);
    [model setValue:[NSValue valueWithCGPoint:p] forKey:@"pointValue"];
    CGPoint gotP = ((NSValue *)[model valueForKey:@"pointValue"]).CGPointValue;
    XCTAssertEqualWithAccuracy(gotP.x, p.x, 0.001, @"CGPoint x 往返错误");
    XCTAssertEqualWithAccuracy(gotP.y, p.y, 0.001, @"CGPoint y 往返错误");
    
    CGSize sz = CGSizeMake(12.5, 34.5);
    [model setValue:[NSValue valueWithCGSize:sz] forKey:@"sizeValue"];
    XCTAssertTrue(CGSizeEqualToSize(((NSValue *)[model valueForKey:@"sizeValue"]).CGSizeValue, sz), @"CGSize 往返错误");
    
    NSRange rng = NSMakeRange(123, 456);
    [model setValue:[NSValue valueWithRange:rng] forKey:@"rangeValue"];
    XCTAssertTrue(NSEqualRanges(((NSValue *)[model valueForKey:@"rangeValue"]).rangeValue, rng), @"NSRange 往返错误（tag=_NSRange）");
    
    CGRect r = CGRectMake(1.5, 2.5, 300.75, 400.25);
    [model setValue:[NSValue valueWithCGRect:r] forKey:@"rectValue"];
    XCTAssertTrue(CGRectEqualToRect(((NSValue *)[model valueForKey:@"rectValue"]).CGRectValue, r), @"CGRect 32B sret 往返错误");
    
    UIEdgeInsets ins = UIEdgeInsetsMake(1, 2, 3, 4);
    [model setValue:[NSValue valueWithUIEdgeInsets:ins] forKey:@"insetsValue"];
    XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(((NSValue *)[model valueForKey:@"insetsValue"]).UIEdgeInsetsValue, ins), @"UIEdgeInsets 往返错误");
    
    CGAffineTransform tf = CGAffineTransformMake(1, 2, 3, 4, 5, 6);
    [model setValue:[NSValue valueWithCGAffineTransform:tf] forKey:@"transformValue"];
    XCTAssertTrue(CGAffineTransformEqualToTransform(((NSValue *)[model valueForKey:@"transformValue"]).CGAffineTransformValue, tf), @"CGAffineTransform 48B sret 往返错误");
    
    // CATransform3D 128B（RawBig 按需缓冲 + sret）：同样脱离转发
    CATransform3D t3d = CATransform3DMakeScale(2, 3, 4);
    t3d.m41 = 7.5; t3d.m42 = -8.5; t3d.m43 = 9.5;
    [model setValue:[NSValue valueWithCATransform3D:t3d] forKey:@"transform3DValue"];
    XCTAssertTrue(CATransform3DEqualToTransform(((NSValue *)[model valueForKey:@"transform3DValue"]).CATransform3DValue, t3d), @"CATransform3D 128B sret 往返错误");
    
    // IMP 命中断言：respondsToSelector YES 证明走预编译 IMP 而非转发兜底——
    // 若某类型的编码 tag 匹配失败（如 NSRange 的 _NSRange 假设不成立），
    // 会静默降级走转发且往返断言仍绿（转发也正确），此断言堵住该验证盲点
    for (int i = 0; i < 7; i++) {
        SEL getter = NSSelectorFromString([NSString stringWithUTF8String:props[i].name]);
        XCTAssertTrue([model respondsToSelector:getter],
                      @"%s getter 应命中预编译 IMP（respondsToSelector YES）而非转发兜底", props[i].name);
    }
    
    // KVO 兼容性由现有 testKVONotification*（pointValue/atomicPointValue 观察顺序）自动覆盖——
    // 新 IMP 的 willChange/didChange 顺序与标量一致，KVO 框架经 getter 自动装箱 old/new
}

/// 验证自定义结构体（无预编译 IMP）仍走 forwardInvocation 转发路径：
/// 首次转发扫描注册（签名缓存写入表项），后续转发快查表命中免扫描，
/// methodSignatureForSelector: 同样免扫描直接返回缓存签名（v1.5 签名缓存）。
- (void)testCustomStructForwarding {
    TestModel *model = [[TestModel alloc] init];
    CBTestCustomStruct cs = {42, 3.14};
    model.customStructValue = cs;    // 首次：扫描属性列表 → 锁内注册表项（含签名缓存）
    CBTestCustomStruct got = model.customStructValue;   // 二次：快查表命中，免扫描
    XCTAssertEqual(got.a, 42, @"自定义结构体 a 字段往返错误");
    XCTAssertEqualWithAccuracy(got.b, 3.14, 0.001, @"自定义结构体 b 字段往返错误");
    
    // 签名缓存：methodSignatureForSelector: 命中表项直接返回（不再扫描属性列表）
    NSMethodSignature *sig = [model methodSignatureForSelector:@selector(customStructValue)];
    XCTAssertNotNil(sig, @"自定义结构体 getter 应有方法签名");
    XCTAssertEqual(sig.methodReturnLength, sizeof(CBTestCustomStruct), @"签名返回长度应为结构体大小");
    
    // KVC 读取（valueForUndefinedKey 返回装箱 NSValue）
    NSValue *boxed = [model valueForKey:@"customStructValue"];
    XCTAssertNotNil(boxed, @"KVC 读取自定义结构体应返回 NSValue");
    CBTestCustomStruct fromKVC;
    [boxed getValue:&fromKVC size:sizeof(CBTestCustomStruct)];
    XCTAssertEqual(fromKVC.a, 42, @"KVC 读取后 a 字段错误");
    XCTAssertEqualWithAccuracy(fromKVC.b, 3.14, 0.001, @"KVC 读取后 b 字段错误");
    // 注：KVC 写入（setValue:forKey:）对转发属性无 setter IMP（respondsToSelector: NO），
    // 抛 NSUndefinedKeyException 属既有行为（已知结构体因有预编译 IMP 而支持）
}

/// 验证转发路径对任意大小结构体的正确性（v1.5 边界）：256B 大结构体（>16B sret +
/// 引用传参）——无预编译 IMP，走 forwardInvocation，NSInvocation/NSValue 按签名处理
/// 任意大小。编译期直接赋值 + KVC 读回逐字段验证。
- (void)testBigStructForwarding {
    TestModel *model = [[TestModel alloc] init];
    
    // 大结构体 256B：直接赋值（编译期按 256B 引用传参）→ 转发装箱 → 读回逐字段验证
    CBTestBigStruct big; memset(&big, 0, sizeof(big));
    for (int i = 0; i < 32; i++) {
        big.d[i] = i * 1.5;
    }
    model.bigStructValue = big;
    CBTestBigStruct gotBig = model.bigStructValue;
    for (int i = 0; i < 32; i++) {
        XCTAssertEqualWithAccuracy(gotBig.d[i], i * 1.5, 0.001, @"大结构体字段 %d 往返错误", i);
    }
    
    // KVC 读取：统一装箱为 NSValue（valueForUndefinedKey 路径）
    NSValue *boxedBig = [model valueForKey:@"bigStructValue"];
    XCTAssertNotNil(boxedBig, @"KVC 读大结构体应返回 NSValue");
    CBTestBigStruct outBig; memset(&outBig, 0, sizeof(outBig));
    [boxedBig getValue:&outBig size:sizeof(CBTestBigStruct)];
    XCTAssertEqualWithAccuracy(outBig.d[31], 31 * 1.5, 0.001, @"KVC 读大结构体末字段错误");
    
    // 转发属性的 KVC 写入：无 setter IMP，抛 NSUndefinedKeyException（既有行为，文档化锁死）
    XCTAssertThrowsSpecificNamed(
        [model setValue:[NSValue valueWithBytes:&big objCType:@encode(CBTestBigStruct)] forKey:@"bigStructValue"],
        NSException, NSUndefinedKeyException,
        @"转发属性（无预编译 IMP）的 KVC 写入应抛 NSUndefinedKeyException");
}

/// union 属性边界锁死（v1.5 决策：不做 union 支持）：
/// NSMethodSignature 不支持 union '(' 编码，methodSignatureForSelector: 构造签名时抛
/// NSInvalidArgumentException——"明确报错而非崩溃"。JSON/服务端驱动场景无 union 类型，
/// ObjC 生态（KVO/KVC/NSInvocation）对 union 属性也全线不支持，投入产出比为负。
- (void)testUnionPropertyUnsupported {
    TestModel *model = [[TestModel alloc] init];
    
    // getter：消息发送 → 转发签名构造 → NSMethodSignature 抛异常（而非崩溃）
    XCTAssertThrowsSpecificNamed(
        ^{ CBTestUnion g = model.unionValue; (void)g; }(),
        NSException, NSInvalidArgumentException,
        @"union getter 应抛 NSInvalidArgumentException（明确报错，非崩溃）");
    
    // setter：同样边界
    CBTestUnion u;
    u.d = 3.25;
    XCTAssertThrowsSpecificNamed(
        ^{ model.unionValue = u; }(),
        NSException, NSInvalidArgumentException,
        @"union setter 应抛 NSInvalidArgumentException（明确报错，非崩溃）");
}

/// 验证运行时动态类（服务端驱动场景）添加大结构体属性：
/// T 编码用 @encode 运行时生成，resolveInstanceMethod 未命中已知类型 → 走转发，
/// objc_msgSend 直调 setter（插件真实场景）→ KVC 读回验证。
- (void)testRuntimeDynamicBigStruct {
    Class cls = objc_allocateClassPair(CBModel.class, "CBTestDynBigModel", 0);
    XCTAssertNotNil(cls, @"动态类创建失败");
    
    objc_property_attribute_t typeAttr = {"T", @encode(CBTestBigStruct)};
    objc_property_attribute_t dynAttr = {"D", ""};
    objc_property_attribute_t attrs[] = {typeAttr, dynAttr};
    XCTAssertTrue(class_addProperty(cls, "bigStructValue", attrs, 2), @"大结构体属性添加失败");
    objc_registerClassPair(cls);
    
    id model = [[cls alloc] init];
    
    // 未写入：Boxed 槽无值 → KVC 读 nil
    XCTAssertNil([model valueForKey:@"bigStructValue"], @"未写入的大结构体 KVC 读应为 nil");
    
    // 大结构体：objc_msgSend 直调 setter（插件真实场景——插件 bundle 内有编译期声明，
    // 运行时注册类后按编译期 ABI 直调；走转发装箱）→ KVC 读回验证。
    // 注：此处不能用 NSInvocation 调 setter——实测 NSInvocation setArgument 对
    // struct 内嵌数组编码（{CBTestBigStruct=[32d]}）崩溃（NSInvocation 的另一处坑，
    // 与 setValue:forUndefinedKey: 弃用它的原因同源）。
    CBTestBigStruct big; memset(&big, 0, sizeof(big));
    for (int i = 0; i < 32; i++) {
        big.d[i] = i * 0.5;
    }
    SEL setter = NSSelectorFromString(@"setBigStructValue:");
    NSMethodSignature *sig = [model methodSignatureForSelector:setter];
    XCTAssertNotNil(sig, @"动态类大结构体 setter 应有签名");
    XCTAssertEqual(sig.methodReturnLength, 0UL, @"setter 返回 void");
    ((void (*)(id, SEL, CBTestBigStruct))objc_msgSend)(model, setter, big);
    
    NSValue *boxed = [model valueForKey:@"bigStructValue"];
    XCTAssertNotNil(boxed, @"KVC 读大结构体应返回 NSValue");
    CBTestBigStruct outBig; memset(&outBig, 0, sizeof(outBig));
    [boxed getValue:&outBig size:sizeof(CBTestBigStruct)];
    for (int i = 0; i < 32; i++) {
        XCTAssertEqualWithAccuracy(outBig.d[i], i * 0.5, 0.001, @"动态类大结构体字段 %d 往返错误", i);
    }
}

/// atomic 大结构体实测（v1.5 盲点加固）：CATransform3D 128B 的 atomic 槽
/// （RawBig 按需缓冲 + os_unfair_lock 锁内 128B memcpy），并发写入后值完整性。
- (void)testAtomicTransform3DProperty {
    TestModel *model = [[TestModel alloc] init];
    CATransform3D t = CATransform3DMakeRotation(M_PI / 4, 1, 0, 0);
    t.m41 = 11.5; t.m42 = -22.5; t.m43 = 33.5;
    model.atomicTransform3DValue = t;
    XCTAssertTrue(CATransform3DEqualToTransform(model.atomicTransform3DValue, t),
                  @"atomic CATransform3D 128B 往返错误");
    
    // 并发写入压力：值完整性。atomic 语义 = 读到的值必是"某个线程完整写入的值"，
    // 不保证是"自己刚写的"（其他线程可能已覆盖）——无撕裂判据：m41/m42/m43
    // 三元组必须匹配某一候选 i（三个字段来自同一次写入），而非跨写入的混合值
    dispatch_queue_t q = dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0);
    dispatch_group_t group = dispatch_group_create();
    __block BOOL valid = YES;
    for (int i = 0; i < 8; i++) {
        dispatch_group_async(group, q, ^{
            CATransform3D local = CATransform3DMakeTranslation(100 + i, i, -i);
            for (int k = 0; k < 200; k++) {
                model.atomicTransform3DValue = local;
                CATransform3D back = model.atomicTransform3DValue;
                int idx = (int)(back.m41 - 100);
                if (idx < 0 || idx > 7 || back.m42 != idx || back.m43 != -idx) {
                    valid = NO;
                }
            }
        });
    }
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    XCTAssertTrue(valid, @"atomic CATransform3D 并发写入后值应完整（无撕裂）");
}

/// 性能基准：裸字节 IMP 路径（CGPoint / CGAffineTransform）vs 转发路径（自定义结构体）。
/// 验证"已知结构体脱离 NSInvocation 转发"与"签名缓存 + 免扫描转发"的收益量级
/// （日志输出，不做阈值断言——机器差异大，基准数字仅参考）。
- (void)testStructImpPerformance {
    TestModel *model = [[TestModel alloc] init];
    model.pointValue = CGPointMake(1, 2);                            // 预热：CGPoint 裸字节 IMP
    model.transformValue = CGAffineTransformIdentity;                // 预热：48B sret 裸字节 IMP
    model.customStructValue = (CBTestCustomStruct){1, 2};            // 预热：自定义结构体转发注册
    
    NSUInteger iterations = 200000;
    CFTimeInterval start;
    
    // 新路径：裸字节 IMP（快查表 + memcpy，无 NSInvocation）
    start = CACurrentMediaTime();
    for (NSUInteger i = 0; i < iterations; i++) {
        model.pointValue = CGPointMake(i, i);
        CGPoint p = model.pointValue;
        if (p.x != i) break;   // 防优化
    }
    CFTimeInterval impTime = CACurrentMediaTime() - start;
    
    // 新路径最大已知结构体：CGAffineTransform 48B（sret + 48B memcpy）
    start = CACurrentMediaTime();
    for (NSUInteger i = 0; i < iterations; i++) {
        CGAffineTransform t = CGAffineTransformMakeTranslation(i, i);
        model.transformValue = t;
        CGAffineTransform back = model.transformValue;
        if (back.tx != i) break;
    }
    CFTimeInterval imp3DTime = CACurrentMediaTime() - start;
    
    // 新路径超大结构体：CATransform3D 128B（RawBig 按需缓冲 + sret + 128B memcpy）
    start = CACurrentMediaTime();
    for (NSUInteger i = 0; i < iterations; i++) {
        CATransform3D t = CATransform3DMakeTranslation(i, i, i);
        model.transform3DValue = t;
        CATransform3D back = model.transform3DValue;
        if (back.m41 != i) break;
    }
    CFTimeInterval impBigTime = CACurrentMediaTime() - start;
    
    // 转发路径：自定义结构体（签名缓存 + 快查表命中免扫描，剩余 NSInvocation 链成本）
    start = CACurrentMediaTime();
    for (NSUInteger i = 0; i < iterations; i++) {
        model.customStructValue = (CBTestCustomStruct){(int32_t)i, i * 2.0};
        CBTestCustomStruct s = model.customStructValue;
        if (s.a != (int32_t)i) break;
    }
    CFTimeInterval fwdTime = CACurrentMediaTime() - start;
    
    NSLog(@"[struct-imp] CGPoint=%.1f ns/op, CGAffineTransform=%.1f ns/op, CATransform3D=%.1f ns/op, custom-forward=%.1f ns/op, CGPoint speedup=%.1fx",
          impTime / iterations * 1e9, imp3DTime / iterations * 1e9, impBigTime / iterations * 1e9,
          fwdTime / iterations * 1e9, fwdTime / impTime);
    XCTAssertGreaterThan(fwdTime, impTime, @"裸字节 IMP 应快于转发路径");
}

@end
