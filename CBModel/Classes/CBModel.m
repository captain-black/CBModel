//
//  CBModel.m
//  CBModel
//
//  Created by Captain Black on 2022/8/9.
//

#import "CBModel.h"

#import <objc/runtime.h>

@interface CBModel ()
@property(nonatomic, readonly, class) YYClassInfo* classInfo;
@property(nonatomic, readonly) NSMutableDictionary<NSString*, id>* sDynamicProperties;// 存放强引用的动态属性
@property(nonatomic, readonly) NSMapTable<NSString*, id>* wDynamicProperties;// 存放弱引用的动态属性
@end

static NSString* _Nullable propertyNameForSelector(Class cls, SEL _cmd) {
    
    do {
        if (![cls respondsToSelector:@selector(classInfo)]) {
            break;
        }
        for (YYClassPropertyInfo* p in [cls classInfo].propertyInfos.allValues) {
            if (sel_isEqual(_cmd, p.getter)) {
                return p.name;
            } else if (sel_isEqual(_cmd, p.setter)) {
                return p.name;
            }
        }
    } while ((cls = [cls superclass]));
    
    return nil;
}

#define IMP_FOR_TYPE(typeName, _TYPE_)                                                  \
static _TYPE_ _getter_for_##typeName##_(CBModel* self, SEL _cmd) {                      \
    NSString* p = propertyNameForSelector([self class], _cmd);                          \
    unsigned int size = sizeof(_TYPE_);                                                 \
    void* value = alloca(size);                                                         \
    if (@available(iOS 11.0, *)) {                                                      \
        [self.sDynamicProperties[p] getValue:value size:size];                          \
    } else {                                                                            \
        [self.sDynamicProperties[p] getValue:value];                                    \
    }                                                                                   \
    return *(_TYPE_*)value;                                                             \
}                                                                                       \
                                                                                        \
static void _setter_for_##typeName##_(CBModel* self, SEL _cmd, _TYPE_ value) {          \
    NSString* p = propertyNameForSelector([self class], _cmd);                          \
    [self willChangeValueForKey:p];                                                     \
    self.sDynamicProperties[p] = [NSValue value:&value withObjCType:@encode(_TYPE_)];   \
    [self willChangeValueForKey:p];                                                     \
}

static id _getter_for_obj_strong_(CBModel* self, SEL _cmd) {
    NSString* p = propertyNameForSelector([self class], _cmd);
    return self.sDynamicProperties[p];
}
                                                                                    
static void _setter_for_obj_strong_(CBModel* self, SEL _cmd, id value) {
    NSString* p = propertyNameForSelector([self class], _cmd);
    [self willChangeValueForKey:p];
    self.sDynamicProperties[p] = value;
    [self didChangeValueForKey:p];
}
                                                                                    
static void _setter_for_obj_copy_(CBModel* self, SEL _cmd, id value) {
    NSString* p = propertyNameForSelector([self class], _cmd);
    [self willChangeValueForKey:p];
    self.sDynamicProperties[p] = [value copy];
    [self didChangeValueForKey:p];
}

static id _getter_for_obj_weak_(CBModel* self, SEL _cmd) {
    NSString* p = propertyNameForSelector([self class], _cmd);
    return [self.wDynamicProperties objectForKey:p];
}
                                                                                    
static void _setter_for_obj_weak_(CBModel* self, SEL _cmd, id value) {
    NSString* p = propertyNameForSelector([self class], _cmd);
    [self willChangeValueForKey:p];
    [self.wDynamicProperties setObject:value
                                forKey:p];
    [self didChangeValueForKey:p];
}

IMP_FOR_TYPE(char, char);
IMP_FOR_TYPE(short, short);
IMP_FOR_TYPE(int, int);
//IMP_FOR_TYPE(long, long);
IMP_FOR_TYPE(longLong, long long);
IMP_FOR_TYPE(unsignedChar, unsigned char);
IMP_FOR_TYPE(unsignedInt, unsigned int);
IMP_FOR_TYPE(unsignedShort, unsigned short);
//IMP_FOR_TYPE(unsignedLong, unsigned long);
IMP_FOR_TYPE(unsignedLongLong, unsigned long long);
IMP_FOR_TYPE(float, float);
IMP_FOR_TYPE(double, double);
IMP_FOR_TYPE(bool, bool);


static IMP impForProperty(BOOL setterOrGetter, YYEncodingType encodingType) {
    switch (encodingType & YYEncodingTypeMask) {
        case YYEncodingTypeBool:
            return setterOrGetter ? (IMP)_setter_for_bool_ : (IMP)_getter_for_bool_;
            break;
        case YYEncodingTypeInt8:
            return setterOrGetter ? (IMP)_setter_for_char_ : (IMP)_getter_for_char_;
            break;
        case YYEncodingTypeUInt8:
            return setterOrGetter ? (IMP)_setter_for_unsignedChar_ : (IMP)_getter_for_unsignedChar_;
            break;
        case YYEncodingTypeInt16:
            return setterOrGetter ? (IMP)_setter_for_short_ : (IMP)_getter_for_short_;
            break;
        case YYEncodingTypeUInt16:
            return setterOrGetter ? (IMP)_setter_for_unsignedShort_ : (IMP)_getter_for_unsignedShort_;
            break;
        case YYEncodingTypeInt32:
            return setterOrGetter ? (IMP)_setter_for_int_ : (IMP)_getter_for_int_;
            break;
        case YYEncodingTypeUInt32:
            return setterOrGetter ? (IMP)_setter_for_unsignedInt_ : (IMP)_getter_for_unsignedInt_;
            break;
        case YYEncodingTypeInt64:
            return setterOrGetter ? (IMP)_setter_for_longLong_ : (IMP)_getter_for_longLong_;
            break;
        case YYEncodingTypeUInt64:
            return setterOrGetter ? (IMP)_setter_for_unsignedLongLong_ : (IMP)_getter_for_unsignedLongLong_;
            break;
        case YYEncodingTypeFloat:
            return setterOrGetter ? (IMP)_setter_for_float_ : (IMP)_getter_for_float_;
            break;
        case YYEncodingTypeDouble:
            return setterOrGetter ? (IMP)_setter_for_double_ : (IMP)_getter_for_double_;
            break;
        case YYEncodingTypeClass:
        case YYEncodingTypeObject:
        case YYEncodingTypeBlock:
            if (encodingType & YYEncodingTypePropertyWeak) {
                return setterOrGetter ? (IMP)_setter_for_obj_weak_ : (IMP)_getter_for_obj_weak_;
            } else if (encodingType & YYEncodingTypePropertyCopy) {
                return setterOrGetter ? (IMP)_setter_for_obj_copy_ : (IMP)_getter_for_obj_strong_;
            } else {
                return setterOrGetter ? (IMP)_setter_for_obj_strong_ : (IMP)_getter_for_obj_strong_;
            }
            break;
    }
    return NULL;
}

@implementation CBModel

#pragma mark - public
static const char modelCustomPropertyMapperKey;
+ (NSDictionary<NSString *,id> *)modelCustomPropertyMapper {
    return objc_getAssociatedObject(self, &modelCustomPropertyMapperKey);
}

+ (void)setModelCustomPropertyMapper:(NSDictionary<NSString *,id> *)modelCustomPropertyMapper {
    objc_setAssociatedObject(self, &modelCustomPropertyMapperKey,
                             modelCustomPropertyMapper,
                             OBJC_ASSOCIATION_COPY_NONATOMIC);
}

static const char modelContainerPropertyGenericClassKey;
+ (NSDictionary<NSString *,id> *)modelContainerPropertyGenericClass {
    return objc_getAssociatedObject(self, &modelContainerPropertyGenericClassKey);
}

+ (void)setModelContainerPropertyGenericClass:(NSDictionary<NSString *,id> *)modelContainerPropertyGenericClass {
    objc_setAssociatedObject(self, &modelContainerPropertyGenericClassKey,
                             modelContainerPropertyGenericClass,
                             OBJC_ASSOCIATION_COPY_NONATOMIC);
}

+ (NSString* _Nullable)_propertyNameForSeletor:(SEL)sel {
    Class cls = self;
    
    if (![cls respondsToSelector:@selector(classInfo)]) {
        return nil;
    }
    for (YYClassPropertyInfo* p in cls.classInfo.propertyInfos.allValues) {
        if (   sel_isEqual(sel, p.getter)
            || sel_isEqual(sel, p.setter)) {
            return p.name;
        }
    }
    
    return nil;
}

@synthesize sDynamicProperties = _sDynamicProperties;
- (NSMutableDictionary<NSString*, id> *)sDynamicProperties {
    if (_sDynamicProperties == nil) {
        _sDynamicProperties = [NSMutableDictionary dictionary];
    }
    return _sDynamicProperties;
}

@synthesize wDynamicProperties = _wDynamicProperties;
- (NSMapTable<NSString*, id> *)wDynamicProperties {
    if (_wDynamicProperties == nil) {
        _wDynamicProperties = [NSMapTable strongToWeakObjectsMapTable];
    }
    return _wDynamicProperties;
}

#pragma mark - 动态实现方法
+ (BOOL)resolveClassMethod:(SEL)sel {
    return [super resolveClassMethod:sel];
}

+ (BOOL)resolveInstanceMethod:(SEL)sel {
    if ([super resolveInstanceMethod:sel]) {
        return YES;
    }
    
    Class cls = self;
    for (YYClassPropertyInfo* p in cls.classInfo.propertyInfos.allValues) {
        IMP imp = nil;
        if (sel_isEqual(sel, p.getter)) {
            imp = impForProperty(NO, p.type);
        } else if (sel_isEqual(sel, p.setter)) {
            imp = impForProperty(YES, p.type);
        }
        if (imp) {
            return class_addMethod(cls, sel, imp, p.typeEncoding.UTF8String);
        }
    }
    
    return NO;
}

+ (YYClassInfo *)classInfo {
    YYClassInfo* classInfo = nil;
    classInfo = objc_getAssociatedObject(self, "classInfo");
    if (classInfo == nil || classInfo.needUpdate) {
        classInfo = [YYClassInfo classInfoWithClass:self];
        objc_setAssociatedObject(self, "classInfo", classInfo, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return classInfo;
}

@end
