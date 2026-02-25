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

#pragma mark - YYModel 兼容性测试

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

- (void)testYYModelWithInvalidJSON {
    NSDictionary *json = @{
        @"name": @"测试",
        @"age": @"不是数字"
    };
    
    YYBasicModel *model = [YYBasicModel yy_modelWithJSON:json];
    
    XCTAssertNotNil(model, @"即使 JSON 类型不匹配，模型也应该创建成功");
    XCTAssertEqualObjects(model.name, @"测试", @"name 应该正确解析");
}

- (void)testYYModelWithEmptyJSON {
    NSDictionary *json = @{};
    
    YYBasicModel *model = [YYBasicModel yy_modelWithJSON:json];
    
    XCTAssertNotNil(model, @"空 JSON 应该创建一个有效的模型");
    XCTAssertNil(model.name, @"name 应该为 nil");
    XCTAssertEqual(model.age, 0, @"age 应该为默认值 0");
}

- (void)testYYModelWithNilJSON {
    YYBasicModel *model = [YYBasicModel yy_modelWithJSON:nil];
    
    XCTAssertNil(model, @"用nil JSON 创建模型是直接返回 nil");
}

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

- (void)testYYModelDescriptionMethod {
    YYBasicModel *model = [[YYBasicModel alloc] init];
    model.name = @"描述测试";
    model.age = 30;
    
    NSString *desc = [model yy_modelDescription];
    
    XCTAssertNotNil(desc, @"YYModel description 不应该为 nil");
    XCTAssertTrue([desc containsString:@"YYBasicModel"], @"description 应该包含类名");
}

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

- (void)testYYModelWithCBModelFeatures {
    YYBasicModel *model = [[YYBasicModel alloc] init];
    model.name = @"CBModel 特性测试";
    model.age = 40;
    
    TestModel *testModel = [[TestModel alloc] init];
    testModel.intValue = 100;
    
    NSDictionary *json = [testModel yy_modelToJSONObject];
    XCTAssertEqualObjects(json[@"intValue"], @100, @"CBModel 子类应该支持 YYModel 转换");
}

@end
