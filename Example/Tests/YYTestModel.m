//
//  YYTestModel.m
//  CBModelTests
//
//  Created by Captain Black on 2025/2/25.
//  Copyright (c) 2025 Captain Black. All rights reserved.
//

#import "YYTestModel.h"

#pragma mark - 基础模型

@implementation YYBasicModel

@end

#pragma mark - 自定义属性名映射模型

@implementation YYMappingModel

+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"userId": @"id",
        @"userName": @"name",
        @"userAge": @"age"
    };
}

@end

#pragma mark - 嵌套模型

@implementation YYAddressModel

@end

@implementation YYUserModel

+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{};
}

@end

#pragma mark - 容器类属性模型

@implementation YYContainerModel

+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{
        @"modelArray": [YYBasicModel class],
        @"modelDict": [YYBasicModel class]
    };
}

@end

#pragma mark - 动态属性模型

@implementation YYDynamicModel

@end

#pragma mark - 协议组合模型

@implementation YYProtocolModel
@dynamic nickName, score;

@end

#pragma mark - 回调方法测试模型

@implementation YYCallbackModel

- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    self.didCustomize = YES;
    if (self.age < 0) {
        self.age = 0;
    }
    return YES;
}

- (BOOL)modelCustomTransformToDictionary:(NSDictionary *)dic {
    self.willConvert = YES;
    return YES;
}

@end

#pragma mark - 复杂类型模型

@implementation YYComplexModel

@end

#pragma mark - 忽略属性模型

@implementation YYIgnoreModel

+ (NSArray *)modelPropertyBlacklist {
    return @[@"password", @"internalId"];
}

@end
