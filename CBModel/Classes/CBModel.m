//
//  CBModel.m
//  CBModel
//
//  Created by Captain Black on 2022/8/9.
//

#import "CBModel.h"

#import <objc/runtime.h>

@interface CBModel ()
@property(nonatomic, readonly, class) NSMutableArray<Class>* _Nullable _proxyClasses;
@property(nonatomic, readonly) NSMutableArray* _Nullable proxyTargets;
@end
@implementation CBModel

#pragma mark - public
+ (void)addProxyClass:(Class)cls {
    NSAssert(cls != self, @"类本身不能作为代理类");
    NSAssert(![self isKindOfClass:cls], @"先祖类不能作为代理类");
    [self._proxyClasses addObject:cls];
    // 添加了代理类，相当于给类扩展了方法和属性，所以要把本类的YYClassInfo标记为需要更新
    [[YYClassInfo classInfoWithClass:self] setNeedUpdate];
}

#pragma mark - <YYModel>
+ (nullable NSDictionary<NSString *,id> *)modelCustomPropertyMapper {
    NSMutableDictionary* mapper = nil;
    NSDictionary* temp = nil;
    
    // 0. 去获取父类的映射表
    Class superClass = [self superclass];
    if ([superClass respondsToSelector:@selector(modelCustomPropertyMapper)]) {
        NSDictionary* mapperFromSuper = [superClass modelCustomPropertyMapper];
        if (mapperFromSuper.count) {
            mapper = mapper?:[NSMutableDictionary dictionary];
            [mapper addEntriesFromDictionary:mapperFromSuper];
        }
    }
    
    // 1. 去获取代理类的映射表
    if (self.proxyClasses.count) {
        mapper = mapper?:[NSMutableDictionary dictionary];
        for (Class cls in self.proxyClasses) {
            temp = [cls modelCustomPropertyMapper];
            [mapper addEntriesFromDictionary:temp];
        }
    }
    
    return mapper;
}

+ (nullable NSDictionary<NSString *,id> *)modelContainerPropertyGenericClass {
    NSMutableDictionary* mapper = nil;
    NSDictionary* temp = nil;
    
    // 0. 去获取父类的映射表
    Class superClass = [self superclass];
    if ([superClass respondsToSelector:@selector(modelContainerPropertyGenericClass)]) {
        NSDictionary* mapperFromSuper = [superClass modelContainerPropertyGenericClass];
        if (mapperFromSuper.count) {
            mapper = mapper?:[NSMutableDictionary dictionary];
            [mapper addEntriesFromDictionary:mapperFromSuper];
        }
    }
    
    // 1. 去获取代理类的映射表
    if (self.proxyClasses.count) {
        mapper = mapper?:[NSMutableDictionary dictionary];
        for (Class cls in self.proxyClasses) {
            temp = [cls modelContainerPropertyGenericClass];
            [mapper addEntriesFromDictionary:temp];
        }
    }
    
    return mapper;
}

#pragma mark - 消息转发
+ (BOOL)instancesRespondToSelector:(SEL)aSelector {
    // 0. 先从超类里匹配
    if ([super instancesRespondToSelector:aSelector]) {
        return YES;
    }
    // 1. 从代理类列表里匹配
    for (Class cls in self.class.proxyClasses.reverseObjectEnumerator) {
        if ([cls instancesRespondToSelector:aSelector]) {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    // 0. 先从超类对象里匹配
    if ([super respondsToSelector:aSelector]) {
        return YES;
    }
    // 1. 从代理对象列表里匹配
    for (id target in self.proxyTargets) {
        if ([target respondsToSelector:aSelector]) {
            return YES;
        }
    }
    // 2. 从代理类列表里匹配
    for (Class cls in self.class.proxyClasses.reverseObjectEnumerator) {
        if ([cls instancesRespondToSelector:aSelector]) {
            return YES;
        }
    }
    
    return NO;
    
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    // 0. 先从代理对象列表里匹配
    for (id target in self.proxyTargets) {
        if ([target respondsToSelector:aSelector]) {
            // 调用代理对象对应的方法来处理
            return [target methodSignatureForSelector:aSelector];
        }
    }
    // 1. 从代理类列表里匹配
    for (Class cls in self.class.proxyClasses.reverseObjectEnumerator) {
        if ([cls instancesRespondToSelector:aSelector]) {
            id target = [[cls alloc] init];// 匹配成功，创建代理对象来处理
            [self.proxyTargets addObject:target];// 持有代理对象
            
            // 调用代理对象对应的方法来处理
            return [target methodSignatureForSelector:aSelector];
        }
    }
    
    return [super methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    SEL aSelector = [anInvocation selector];
    
    // 0. 先从代理对象列表里匹配
    for (id target in self.proxyTargets) {
        if ([target respondsToSelector:aSelector]) {
            // 调用代理对象对应的方法来处理
            return [anInvocation invokeWithTarget:target];
        }
    }
    // 1. 从代理类列表里匹配
    for (Class cls in self.class.proxyClasses.reverseObjectEnumerator) {
        if ([cls instancesRespondToSelector:aSelector]) {
            id target = [[cls alloc] init];// 匹配成功，创建代理对象来处理
            [self.proxyTargets addObject:target];// 持有代理对象
            // 调用代理对象对应的方法来处理
            return [anInvocation invokeWithTarget:target];
        }
    }
    
    [super forwardInvocation:anInvocation];
}

#pragma mark - getter & setter
+ (NSArray<Class> *)proxyClasses {
    return self._proxyClasses;
}

static const char _proxyClassesKey;
+ (NSMutableArray<Class> *_Nullable)_proxyClasses {
    // 因为Class在底层也是一个NSObject对象，所以也能用对象关联
    NSMutableArray *__proxyClasses = objc_getAssociatedObject(self,
                                                             &_proxyClassesKey);
    if (!__proxyClasses) {
        __proxyClasses = [NSMutableArray array];
        objc_setAssociatedObject(self, &_proxyClassesKey, __proxyClasses,
                                 OBJC_ASSOCIATION_RETAIN);
        
        // 获取父类的代理类列表，这里会造成一定的内存浪费
        Class superClass = [self superclass];
        if ([superClass respondsToSelector:@selector(_proxyClasses)]) {
            NSArray* proxyClassesFromSuper = superClass._proxyClasses;
            if (proxyClassesFromSuper.count) {
                [__proxyClasses addObjectsFromArray:proxyClassesFromSuper];
            }
        }
    }
    return __proxyClasses;
}

@synthesize proxyTargets = _proxyTargets;
- (NSMutableArray *_Nullable)proxyTargets {
    if (!_proxyTargets) {
        _proxyTargets = [NSMutableArray array];
    }
    return _proxyTargets;
}

@end
