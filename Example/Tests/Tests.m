//
//  Tests.m
//  CBModelTests
//
//  Created by Captain Black on 12/28/2022.
//  Copyright (c) 2022 Captain Black. All rights reserved.
//

@import XCTest;
#import "TestModel.h"

@interface Tests : XCTestCase
@property (nonatomic, assign) BOOL kvoObserverCalled;
@property (nonatomic, assign) NSInteger kvoNewIntValue;
@property (nonatomic, assign) long double kvoNewLdValue;
@property (nonatomic, strong) NSString *kvoNewStringValue;
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

- (void)testIntProperty {
    TestModel *model = [[TestModel alloc] init];
    model.intValue = 42;
    XCTAssertEqual(model.intValue, 42, @"int 属性应该正常工作");
}

- (void)testFloatProperty {
    TestModel *model = [[TestModel alloc] init];
    model.floatValue = 3.14f;
    XCTAssertEqualWithAccuracy(model.floatValue, 3.14f, 0.001, @"float 属性应该正常工作");
}

- (void)testDoubleProperty {
    TestModel *model = [[TestModel alloc] init];
    model.doubleValue = 2.71828;
    XCTAssertEqualWithAccuracy(model.doubleValue, 2.71828, 0.00001, @"double 属性应该正常工作");
}

- (void)testBoolProperty {
    TestModel *model = [[TestModel alloc] init];
    model.boolValue = YES;
    XCTAssertTrue(model.boolValue, @"bool 属性应该正常工作");
    
    model.boolValue = NO;
    XCTAssertFalse(model.boolValue, @"bool 属性应该正常工作");
}

- (void)testCharProperty {
    TestModel *model = [[TestModel alloc] init];
    model.charValue = 'A';
    XCTAssertEqual(model.charValue, 'A', @"char 属性应该正常工作");
}

- (void)testShortProperty {
    TestModel *model = [[TestModel alloc] init];
    model.shortValue = 1000;
    XCTAssertEqual(model.shortValue, 1000, @"short 属性应该正常工作");
}

- (void)testLongLongProperty {
    TestModel *model = [[TestModel alloc] init];
    model.longValue = 1234567890LL;
    XCTAssertEqual(model.longValue, 1234567890LL, @"long long 属性应该正常工作");
}

- (void)testUnsignedIntProperty {
    TestModel *model = [[TestModel alloc] init];
    model.unsignedIntValue = 999;
    XCTAssertEqual(model.unsignedIntValue, 999, @"unsigned int 属性应该正常工作");
}

- (void)testUnsignedLongLongProperty {
    TestModel *model = [[TestModel alloc] init];
    model.unsignedLongLongValue = 9876543210ULL;
    XCTAssertEqual(model.unsignedLongLongValue, 9876543210ULL, @"unsigned long long 属性应该正常工作");
}

#pragma mark - 对象类型测试

- (void)testStrongStringProperty {
    TestModel *model = [[TestModel alloc] init];
    NSString *testString = @"Hello, World!";
    model.strongString = testString;
    XCTAssertEqualObjects(model.strongString, testString, @"strong string 属性应该正常工作");
}

- (void)testCopyStringProperty {
    TestModel *model = [[TestModel alloc] init];
    NSMutableString *mutableString = [NSMutableString stringWithString:@"原始值"];
    model.cpString = mutableString;
    [mutableString appendString:@" 修改后"];
    XCTAssertEqualObjects(model.cpString, @"原始值", @"copy string 属性应该复制值");
}

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

- (void)testArrayProperty {
    TestModel *model = [[TestModel alloc] init];
    NSArray *array = @[@"one", @"two", @"three"];
    model.arrayValue = array;
    XCTAssertEqualObjects(model.arrayValue, array, @"array 属性应该正常工作");
}

- (void)testDictProperty {
    TestModel *model = [[TestModel alloc] init];
    NSDictionary *dict = @{@"key": @"value"};
    model.dictValue = dict;
    XCTAssertEqualObjects(model.dictValue, dict, @"dictionary 属性应该正常工作");
}

#pragma mark - Atomic 属性测试

- (void)testAtomicIntProperty {
    TestModel *model = [[TestModel alloc] init];
    model.atomicIntValue = 100;
    XCTAssertEqual(model.atomicIntValue, 100, @"atomic int 属性应该正常工作");
}

- (void)testAtomicStringProperty {
    TestModel *model = [[TestModel alloc] init];
    NSString *testString = @"Atomic String";
    model.atomicString = testString;
    XCTAssertEqualObjects(model.atomicString, testString, @"atomic string 属性应该正常工作");
}

#pragma mark - 线程安全测试

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

#pragma mark - 边界情况测试

- (void)testNilObjectProperty {
    TestModel *model = [[TestModel alloc] init];
    model.strongString = nil;
    XCTAssertNil(model.strongString, @"object 属性应该接受 nil");
}

- (void)testZeroValueProperty {
    TestModel *model = [[TestModel alloc] init];
    model.intValue = 0;
    XCTAssertEqual(model.intValue, 0, @"属性应该接受零值");
}

- (void)testNegativeValueProperty {
    TestModel *model = [[TestModel alloc] init];
    model.intValue = -100;
    XCTAssertEqual(model.intValue, -100, @"属性应该接受负值");
}

- (void)testLargeValueProperty {
    TestModel *model = [[TestModel alloc] init];
    model.longValue = LONG_MAX;
    XCTAssertEqual(model.longValue, LONG_MAX, @"属性应该接受大值");
}

#pragma mark - KVO 测试

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
}

- (void)testKVOForIntProperty {
    TestModel *model = [[TestModel alloc] init];
    self.kvoModel = model;
    
    [model addObserver:self forKeyPath:@"intValue" options:NSKeyValueObservingOptionNew context:nil];
    
    model.intValue = 100;
    
    XCTAssertTrue(self.kvoObserverCalled, @"KVO 观察者应该被调用");
    XCTAssertEqual(self.kvoNewIntValue, model.intValue, @"KVO 变更应该包含新值");
    
    [model removeObserver:self forKeyPath:@"intValue"];
}

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

- (void)testKVOForAtomicProperty {
    TestModel *model = [[TestModel alloc] init];
    self.kvoModel = model;
    
    [model addObserver:self forKeyPath:@"atomicIntValue" options:NSKeyValueObservingOptionNew context:nil];
    
    model.atomicIntValue = 200;
    
    XCTAssertTrue(self.kvoObserverCalled, @"atomic 属性的 KVO 观察者应该被调用");
    
    [model removeObserver:self forKeyPath:@"atomicIntValue"];
}

#pragma mark - NSCoding 测试

- (void)testNSCoding {
    TestModel *model = [[TestModel alloc] init];
    model.intValue = 42;
    model.strongString = @"测试字符串";
    model.boolValue = YES;
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:model];
    XCTAssertNotNil(data, @"NSCoding 应该能编码模型");
    
    TestModel *decodedModel = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    XCTAssertNotNil(decodedModel, @"NSCoding 应该能解码模型");
    XCTAssertEqual(decodedModel.intValue, 42, @"解码后的 int 值应该匹配");
    XCTAssertEqualObjects(decodedModel.strongString, @"测试字符串", @"解码后的 string 值应该匹配");
    XCTAssertEqual(decodedModel.boolValue, YES, @"解码后的 bool 值应该匹配");
}

#pragma mark - NSCopying 测试

- (void)testNSCopying {
    TestModel *model = [[TestModel alloc] init];
    model.intValue = 100;
    model.strongString = @"原始值";
    
    TestModel *copyModel = [model copy];
    XCTAssertNotNil(copyModel, @"复制对象不应该为 nil");
    XCTAssertEqual(copyModel.intValue, 100, @"复制后的 int 值应该匹配");
    XCTAssertEqualObjects(copyModel.strongString, @"原始值", @"复制后的 string 值应该匹配");
    
    copyModel.intValue = 200;
    XCTAssertNotEqual(model.intValue, copyModel.intValue, @"修改复制对象不应该影响原对象");
}

#pragma mark - Description 测试

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

@end
