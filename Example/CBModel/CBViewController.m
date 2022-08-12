//
//  CBViewController.m
//  CBModel
//
//  Created by Captain Black on 08/09/2022.
//  Copyright (c) 2022 Captain Black. All rights reserved.
//

#import "CBViewController.h"

#import <CBModel/CBModel.h>

@protocol ModelA
@property(nonatomic, copy, setter=setAA:, getter=AA) NSString* nameA;
@property(nonatomic, weak) NSArray* ar;
@optional
- (id)testMethod;
@end
@interface ModelA : CBModel
@property(nonatomic, copy) NSString* nameA;
@end
@implementation ModelA

+ (NSDictionary<NSString *,id> *)modelCustomPropertyMapper {
    NSMutableDictionary* dic = [NSMutableDictionary dictionaryWithDictionary:[super modelCustomPropertyMapper]];
    [dic addEntriesFromDictionary:@{
        @"AA": @"a"
    }];
    return dic;
}

@end

@protocol ModelB
@property(nonatomic, copy) NSString* nameB;
@end
@interface ModelB : CBModel <ModelB>
@property(nonatomic, copy) NSString* nameB;
@end
@implementation ModelB

+ (NSDictionary<NSString *,id> *)modelCustomPropertyMapper {
    NSMutableDictionary* dic = [NSMutableDictionary dictionaryWithDictionary:[super modelCustomPropertyMapper]];
    [dic addEntriesFromDictionary:@{
        @"nameB": @"b.name"
    }];
    return dic;
}

@end

@interface MainModel: CBModel <ModelA, ModelB>
@property(nonatomic, copy) NSString* mainName;
@property(nonatomic, assign) int number;
@end
@implementation MainModel
@dynamic nameA, nameB, ar;
+ (NSDictionary<NSString *,id> *)modelCustomPropertyMapper {
    NSMutableDictionary* dic = [NSMutableDictionary dictionaryWithDictionary:[super modelCustomPropertyMapper]];
    [dic addEntriesFromDictionary:@{
        @"number": @"main.num",
        @"nameA": @"a"
    }];
    return dic;
}
@end

@protocol ModelC
@property(nonatomic, copy) NSString* nameC;
@end
@interface ModelC : CBModel <ModelC>

@end
@implementation ModelC
@synthesize nameC;
+ (NSDictionary<NSString *,id> *)modelCustomPropertyMapper {
    NSMutableDictionary* dic = [NSMutableDictionary dictionaryWithDictionary:[super modelCustomPropertyMapper]];
    [dic addEntriesFromDictionary:@{
        @"nameC": @"c"
    }];
    return dic;
}
@end

@interface MainModelEx : MainModel <ModelC>

@end
@implementation MainModelEx
@dynamic nameC;

@end

@interface CBViewController ()
@property(nonatomic, weak) id delegate;
@end

@implementation CBViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    NSDictionary* json = @{
        @"mainName": @"这是main的名字",
        @"main": @{
            @"num": @12345
        },
        @"a": @"这是a的名字",
        @"b": @{
            @"name": @"这是b的名字"
        },
        @"c": @"这是c的名字"
    };
    
    MainModel* m = nil;
    
    // 常规的属性转化
    m = [MainModel yy_modelWithJSON:json];
    NSLog(@"mainName: %@", m.mainName);
    NSLog(@"number: %d", m.number);
    
    // 增加代理类ModelA代理对应协议的nameA属性
    NSLog(@"nameA: %@", m.nameA);
    
    // 增加代理类ModelB代理对应协议的nameB属性
    NSLog(@"nameB: %@", m.nameB);
    
    m = [[MainModel alloc] init];
    NSString* s = [NSString stringWithFormat:@"%s_d", "23"];
    @autoreleasepool {
        NSArray* ar = @[@"1", @"2"];
        m.ar = ar;
        NSLog(@"%@", m.ar);
    }
    
    NSLog(@"nameA: %@", s);
    
    self.delegate = nil;
    
    MainModelEx* mx = nil;
    
    // 增加代理类ModelC代理对应协议的nameC属性
    NSMutableDictionary* dic = [NSMutableDictionary dictionary];
    [dic addEntriesFromDictionary:ModelA.modelCustomPropertyMapper];
    [dic addEntriesFromDictionary:ModelB.modelCustomPropertyMapper];
    [dic addEntriesFromDictionary:MainModel.modelCustomPropertyMapper];
    [dic addEntriesFromDictionary:ModelC.modelCustomPropertyMapper];
    [dic addEntriesFromDictionary:MainModelEx.modelCustomPropertyMapper];
    MainModelEx.modelCustomPropertyMapper = dic;
    
    mx = [MainModelEx yy_modelWithJSON:json];
    NSLog(@"mainName: %@", mx.mainName);
    NSLog(@"number: %d", mx.number);
    NSLog(@"nameA: %@", mx.nameA);
    NSLog(@"nameB: %@", mx.nameB);
    NSLog(@"nameC: %@", mx.nameC);

    NSDictionary* _ = [mx yy_modelToJSONObject];
    NSLog(@"%@", _);
    
}

- (void)didReceiveMemoryWarning
{
    NSLog(@"delegate: %@", self.delegate);
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
