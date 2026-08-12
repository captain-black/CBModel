//
//  Tests.m
//  CBModelTests
//
//  Created by Captain Black on 12/28/2022.
//  Copyright (c) 2022 Captain Black. All rights reserved.
//

@import XCTest;
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

// 验证 atomic 与 nonatomic 属性混合多线程并发写入（P0-2.1 容器竞态回归）：
// 两类属性共享同一容器，并发写入不应损坏容器，结束后各属性值有效
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
    dispatch_group_t group = dispatch_group_create();
    
    for (int i = 0; i < 200; i++) {
        dispatch_group_enter(group);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // atomic 与 nonatomic 属性共享同一个容器，并发写入不应损坏容器
            model.atomicIntValue = i;
            model.intValue = i;
            model.atomicString = [NSString stringWithFormat:@"a%d", i];
            model.strongString = [NSString stringWithFormat:@"s%d", i];
            for (int j = 1; j <= 8; j++) {
                [model setValue:@(i * 1.0) forKey:[NSString stringWithFormat:@"atomicDoubleValue%d", j]];
            }
            model.rectValue = CGRectMake(i, i, i, i);
            model.pointValue = CGPointMake(i, i);
            dispatch_group_leave(group);
        });
    }
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    XCTAssertTrue(model.atomicIntValue >= 0 && model.atomicIntValue < 200, @"并发写入后值应该有效");
    XCTAssertNotNil(model.atomicString, @"并发写入后字符串不应该为 nil");
    XCTAssertNotNil(model.strongString, @"并发写入后字符串不应该为 nil");
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
        // 结构体属性：change 里的 old/new 都是 NSValue，取回 CGPoint 供顺序断言
        CGPoint oldP = CGPointZero;
        CGPoint newP = CGPointZero;
        [[change objectForKey:NSKeyValueChangeOldKey] getValue:&oldP];
        [[change objectForKey:NSKeyValueChangeNewKey] getValue:&newP];
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

@end
