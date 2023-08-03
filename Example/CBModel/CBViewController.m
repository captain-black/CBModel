//
//  CBViewController.m
//  CBModel
//
//  Created by Captain Black on 12/28/2022.
//  Copyright (c) 2022 Captain Black. All rights reserved.
//

#import "CBViewController.h"

#import <CBModel/CBModel.h>

struct kkw {
    char a;
    short d;
};

union uwd {
    char a[2];
    short c;
};

@protocol TestProtocol <NSObject>

@property (assign) long type;
@property (nonatomic, assign) CGFloat ftype;
@property (nonatomic) NSString* str;
@property (nonatomic, assign) struct kkw k;
@property (nonatomic) Class cls;

@end

@protocol TTestProtocol <NSObject>

@property (nonatomic) SEL sell;
@property (nonatomic) NSArray* ccc;
@property (nonatomic) union uwd d;
@property (nonatomic) long double lddd;
@property (nonatomic) int* iii;

@end

@interface TModel : CBModel

@end

@implementation TModel

@end

@interface TModel (T) <TestProtocol>

@end

@implementation TModel (T)
@dynamic type, ftype, str, k, cls;

@end

@interface TTModel : TModel <TTestProtocol>

@end
@implementation TTModel
@dynamic sell, ccc, lddd, d, iii;

@end

@interface CBViewController ()

@end

@implementation CBViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    TTModel* m = [TTModel new];
    [m addObserver:self forKeyPath:@"type"
           options:NSKeyValueObservingOptionNew
           context:NULL];
    union uwd vv;
    vv.a[0] = 'a';
    vv.a[1] = 'b';
    m.d = vv;
    m.ccc = @[@"a", @"b"];
    m.cls = self.class;
    m.sell = @selector(viewDidLoad);
    m.type = 345;
    m.str = @"哈哈哈";
    m.ftype = 0.23;
    m.k = (struct kkw){'c', 4};
    m.lddd = 9992;
    m.iii = (void*)0x02;
    
    for (int i = 0; i < 3; i++) {
        NSLog(@"%i, %c, %c", m.d.c, m.d.a[0], m.d.a[1]);
        NSLog(@"%@", m.ccc);
        NSLog(@"%@", m.cls);
        NSLog(@"%@", NSStringFromSelector(m.sell));
        NSLog(@"%ld", m.type);
        NSLog(@"%@", m.str);
        NSLog(@"%f", m.ftype);
        NSLog(@"a: %c, d: %d", m.k.a, m.k.d);
        NSLog(@"%Lf", m.lddd);
        NSLog(@"0x%08x", m.iii);
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"type"]) {
        NSLog(@"%@", change);
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
