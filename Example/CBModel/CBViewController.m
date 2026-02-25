//
//  CBViewController.m
//  CBModel
//
//  Created by Captain Black on 08/09/2022.
//  Copyright (c) 2022 Captain Black. All rights reserved.
//

#import "CBViewController.h"

#import <YYModel/YYModel.h>
#import <CBModel/CBModel.h>

@protocol ModelA <YYModel>
@property(nonatomic, copy, setter=setAA:, getter=AA) NSString* nameA;
@property(nonatomic, weak) NSArray* ar;
@optional
- (id)testMethod;
@end
@interface ModelA : CBModel
@property(nonatomic, copy) NSString* nameA;
@end
@implementation ModelA

@end

@protocol ModelB
@property(nonatomic, copy) NSString* nameB;
@end
@interface ModelB : CBModel <ModelB>

@end
@implementation ModelB
@dynamic nameB;

@end

@interface MainModel: CBModel <ModelA, ModelB>
@property(nonatomic, copy) NSString* mainName;
@property(nonatomic, assign) int number;
@end
@implementation MainModel
@dynamic nameA, nameB, ar;

@end

@protocol ModelC
@property(nonatomic, copy) NSString* nameC;
@property (nonatomic, assign) CGSize size;
@end
@interface ModelC : CBModel <ModelC>

@end
@implementation ModelC
@synthesize nameC, size;
@end

@interface MainModelEx : MainModel <ModelC>

@end
@implementation MainModelEx
@dynamic nameC, size;

@end

@interface CBViewController ()
@property(nonatomic, weak) id delegate;
@end

@implementation CBViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

@end
