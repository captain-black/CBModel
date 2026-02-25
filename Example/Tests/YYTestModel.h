//
//  YYTestModel.h
//  CBModelTests
//
//  Created by Captain Black on 2025/2/25.
//  Copyright (c) 2025 Captain Black. All rights reserved.
//

#import "CBModel.h"
@import YYModel;

#pragma mark - 基础模型

@interface YYBasicModel : CBModel <YYModel>
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger age;
@property (nonatomic, assign) BOOL isMale;
@property (nonatomic, assign) double height;
@property (nonatomic, assign) float weight;
@end

#pragma mark - 自定义属性名映射模型

@interface YYMappingModel : CBModel <YYModel>
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *userName;
@property (nonatomic, assign) NSInteger userAge;
@end

#pragma mark - 嵌套模型

@interface YYAddressModel : CBModel <YYModel>
@property (nonatomic, copy) NSString *city;
@property (nonatomic, copy) NSString *street;
@property (nonatomic, assign) NSInteger zipCode;
@end

@interface YYUserModel : CBModel <YYModel>
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) YYAddressModel *address;
@end

#pragma mark - 容器类属性模型

@interface YYContainerModel : CBModel <YYModel>
@property (nonatomic, copy) NSArray *stringArray;
@property (nonatomic, copy) NSArray *modelArray;
@property (nonatomic, copy) NSDictionary *stringDict;
@property (nonatomic, copy) NSDictionary *modelDict;
@end

#pragma mark - 动态属性模型

@interface YYDynamicModel : CBModel <YYModel>
@property (nonatomic, copy) NSString *staticName;
@end

#pragma mark - 协议组合模型

@protocol YYUserInfo <YYModel>
@property (nonatomic, copy) NSString *nickName;
@property (nonatomic, assign) NSInteger score;
@end

@interface YYProtocolModel : CBModel <YYUserInfo>
@property (nonatomic, copy) NSString *realName;
@end

#pragma mark - 回调方法测试模型

@interface YYCallbackModel : CBModel <YYModel>
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger age;
@property (nonatomic, assign) BOOL didCustomize;
@property (nonatomic, assign) BOOL willConvert;
@end

#pragma mark - 复杂类型模型

@interface YYComplexModel : CBModel <YYModel>
@property (nonatomic, assign) char charValue;
@property (nonatomic, assign) short shortValue;
@property (nonatomic, assign) long longValue;
@property (nonatomic, assign) long long llValue;
@property (nonatomic, assign) unsigned int uintValue;
@property (nonatomic, assign) unsigned long long ullValue;
@property (nonatomic, assign) CGSize sizeValue;
@property (nonatomic, assign) CGRect rectValue;
@property (nonatomic, assign) CGPoint pointValue;
@end

#pragma mark - 忽略属性模型

@interface YYIgnoreModel : CBModel <YYModel>
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, assign) NSInteger internalId;
@end
