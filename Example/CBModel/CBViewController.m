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
@property(nonatomic, copy) NSString* nameA;
@end
@interface ModelA : CBModel
@property(nonatomic, copy) NSString* nameA;
@end
@implementation ModelA

+ (NSDictionary<NSString *,id> *)modelCustomPropertyMapper {
    return @{
        @"nameA": @"a"
    };
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
    return @{
        @"nameB": @"b.name"
    };
}

@end

@interface MainModel: CBModel <ModelA, ModelB>
@property(nonatomic, copy) NSString* mainName;
@property(nonatomic, assign) int number;
@end
@implementation MainModel
@dynamic nameA, nameB;
+ (NSDictionary<NSString *,id> *)modelCustomPropertyMapper {
    NSMutableDictionary* dic = [NSMutableDictionary dictionaryWithDictionary:[super modelCustomPropertyMapper]];
    [dic addEntriesFromDictionary:@{
        @"number": @"main.num"
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
    return @{
        @"nameC": @"c"
    };
}
@end

@interface MainModelEx : MainModel <ModelC>

@end
@implementation MainModelEx
@dynamic nameC;

@end

@interface CBViewController ()

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
    
    m = [MainModel yy_modelWithJSON:json];
    NSLog(@"mainName: %@", m.mainName);
    NSLog(@"number: %d", m.number);
    
    [MainModel addProxyClass:ModelA.class];
    m = [MainModel yy_modelWithJSON:json];
    NSLog(@"nameA: %@", m.nameA);
    [MainModel addProxyClass:ModelB.class];
    [m yy_modelSetWithJSON:json];
    NSLog(@"nameB: %@", m.nameB);
    
    MainModelEx* mx = nil;
    [MainModelEx addProxyClass:ModelC.class];
    mx = [MainModelEx yy_modelWithJSON:json];
    NSLog(@"mainName: %@", mx.mainName);
    NSLog(@"number: %d", mx.number);
    NSLog(@"nameA: %@", mx.nameA);
    NSLog(@"nameB: %@", mx.nameB);
    NSLog(@"nameC: %@", mx.nameC);
    
    NSDictionary* dic = [mx yy_modelToJSONObject];
    NSLog(@"%@", dic);
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
