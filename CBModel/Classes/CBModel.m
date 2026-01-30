//
//  CBModel.m
//  CBModel
//
//  Created by Captain Black on 2023/7/14.
//

#import "CBModel.h"

#import <objc/runtime.h>
#import <objc/message.h>

@interface CBModel ()
+ (NSString* _Nullable)propNameForSel:(SEL)sel;
+ (NSString* _Nullable)propNameForSelector:(NSString*)selectorName;
@end

#define IMP_FOR_TYPE(typeName, _TYPE_)                                                  \
static _TYPE_ _getter_for_##typeName##_(CBModel* self, SEL _cmd) {                      \
    NSString* p = [[self class] propNameForSel:_cmd];                                   \
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
    NSString* p = [[self class] propNameForSel:_cmd];                                   \
    self.sDynamicProperties[p] = [NSValue value:&value withObjCType:@encode(_TYPE_)];   \
}


static id _getter_for_obj_strong_(CBModel* self, SEL _cmd) {
    NSString* p = [[self class] propNameForSel:_cmd];
    return self.sDynamicProperties[p];
}

static void _setter_for_obj_strong_(CBModel* self, SEL _cmd, id value) {
    NSString* p = [[self class] propNameForSel:_cmd];
    self.sDynamicProperties[p] = value;
}

static void _setter_for_obj_copy_(CBModel* self, SEL _cmd, id value) {
    NSString* p = [[self class] propNameForSel:_cmd];
    self.sDynamicProperties[p] = [value copy];
}

static id _getter_for_obj_weak_(CBModel* self, SEL _cmd) {
    NSString* p = [[self class] propNameForSel:_cmd];
    return [self.wDynamicProperties objectForKey:p];
}

static void _setter_for_obj_weak_(CBModel* self, SEL _cmd, id value) {
    NSString* p = [[self class] propNameForSel:_cmd];
    [self.wDynamicProperties setObject:value
                                forKey:p];
}

static void* _getter_for_pointer_(CBModel* self, SEL _cmd) {
    NSString* p = [[self class] propNameForSel:_cmd];
    NSValue* val = [self.sDynamicProperties objectForKey:p];
    return [val pointerValue];
}

static void _setter_for_pointer_(CBModel* self, SEL _cmd, const void* value) {
    NSString* p = [[self class] propNameForSel:_cmd];
    NSValue* val = [NSValue valueWithPointer:value];
    [self.sDynamicProperties setObject:val
                                forKey:p];
}

static void* _getter_for_sel_(CBModel* self, SEL _cmd) {
    NSString* p = [[self class] propNameForSel:_cmd];
    NSValue* val = [self.sDynamicProperties objectForKey:p];
    return (__bridge void*)[val nonretainedObjectValue];
}

static void _setter_for_sel_(CBModel* self, SEL _cmd, __unsafe_unretained id value) {
    NSString* p = [[self class] propNameForSel:_cmd];
    NSValue* val = [NSValue valueWithNonretainedObject:value];
    [self.sDynamicProperties setObject:val
                                forKey:p];
}

IMP_FOR_TYPE(char, char);
IMP_FOR_TYPE(short, short);
IMP_FOR_TYPE(int, int);
IMP_FOR_TYPE(long, long);
IMP_FOR_TYPE(longLong, long long);
IMP_FOR_TYPE(unsignedChar, unsigned char);
IMP_FOR_TYPE(unsignedInt, unsigned int);
IMP_FOR_TYPE(unsignedShort, unsigned short);
IMP_FOR_TYPE(unsignedLong, unsigned long);
IMP_FOR_TYPE(unsignedLongLong, unsigned long long);
IMP_FOR_TYPE(float, float);
IMP_FOR_TYPE(double, double);
IMP_FOR_TYPE(longDouble, long double);
IMP_FOR_TYPE(bool, bool);

/*
 在Objective-C中，编码类型（encodingType）是用字符串表示的编码描述，用于标识属性、方法参数、返回类型等的数据类型。下面是一些常见的编码类型及其对应的含义：
 
 c：表示char类型
 i：表示int类型
 s：表示short类型
 l：表示long类型
 q：表示long long类型
 C：表示unsigned char类型
 I：表示unsigned int类型
 S：表示unsigned short类型
 L：表示unsigned long类型
 Q：表示unsigned long long类型
 f：表示float类型
 d：表示double类型
 B：表示BOOL类型
 v：表示void类型
 *：表示char *类型（C字符串）
 @：表示对象类型（id类型），后面可以跟随一个字符串，表示对象的类名，例如@"NSString"表示NSString类对象
 #：表示类类型（Class类型）
 :：表示方法选择器（SEL类型）
 [arrayType]：表示数组类型，其中arrayType是数组元素的编码类型，例如[NSString]表示NSString类型的数组
 {name=type}：表示结构体类型，其中name是结构体名称，type是结构体的编码类型，例如{CGPoint=dd}表示CGPoint结构体类型，包含两个double类型的成员变量
 (name=type)：表示联合体类型，与结构体类似
 
 这些编码类型是通过Objective-C的运行时机制中的编码规则来定义的，用于描述类型信息。在编码类型中，可能会出现一些特殊符号和组合，用于表示更复杂的数据类型。
 
 需要注意的是，编码类型是基于C语言的类型系统，所以其中的一些标识符可能与C语言类型相对应。但是，在Objective-C中，编码类型可以更精确地表示对象类型、类类型、方法选择器等。
 
 请注意，上述列表仅包含了一些常见的编码类型，而实际上还有更多的编码类型可以用于描述不同的数据类型。如果你需要详细的编码类型列表及其说明，可以参考苹果官方文档中关于Objective-C运行时机制的部分，其中有完整的编码类型规范和说明。
 //*/
static IMP imp_for_property(BOOL isSetter, const char* propAttributes) {
    char *typeEncoding = strchr(propAttributes, 'T');
    switch (*(typeEncoding+1)) {
        case 'c': // char
        {
            return isSetter? (IMP)_setter_for_char_ : (IMP)_getter_for_char_;
        } break;
        case 'i': // int
        {
            return isSetter? (IMP)_setter_for_int_ : (IMP)_getter_for_int_;
        } break;
        case 's': // short
        {
            return isSetter? (IMP)_setter_for_short_ : (IMP)_getter_for_short_;
        } break;
        case 'l': // long
        {
            return isSetter? (IMP)_setter_for_long_ : (IMP)_getter_for_long_;
        } break;
        case 'q': // long long
        {
            return isSetter? (IMP)_setter_for_longLong_ : (IMP)_getter_for_longLong_;
        } break;
        case 'C': // unsigned char
        {
            return isSetter? (IMP)_setter_for_unsignedChar_ : (IMP)_getter_for_unsignedChar_;
        } break;
        case 'I': // unsigned int
        {
            return isSetter? (IMP)_setter_for_unsignedInt_ : (IMP)_getter_for_unsignedInt_;
        } break;
        case 'S': // unsigned short
        {
            return isSetter? (IMP)_setter_for_unsignedShort_ : (IMP)_getter_for_unsignedShort_;
        } break;
        case 'L': // unsigned long
        {
            return isSetter? (IMP)_setter_for_unsignedLong_ : (IMP)_getter_for_unsignedLong_;
        } break;
        case 'Q': // unsigned long long
        {
            return isSetter? (IMP)_setter_for_unsignedLongLong_ : (IMP)_getter_for_unsignedLongLong_;
        } break;
        case 'f': // float
        {
            return isSetter? (IMP)_setter_for_float_ : (IMP)_getter_for_float_;
        } break;
        case 'd': // double
        {
            return isSetter? (IMP)_setter_for_double_ : (IMP)_getter_for_double_;
        } break;
        case 'D': // long double
        {
            return isSetter? (IMP)_setter_for_longDouble_ : (IMP)_getter_for_longDouble_;
        } break;
        case 'B': // BOOL
        {
            return isSetter? (IMP)_setter_for_bool_ : (IMP)_getter_for_bool_;
        } break;
        case '^': // Pointer
        {
            return isSetter? (IMP)_setter_for_pointer_ : (IMP)_getter_for_pointer_;
        } break;
        case '@': // NSObject
        case '#': // class，class本质上也是一个NSObject，所以getter、setter可以共用
        {
            char* attr;
            // OC 对象属性还要区分不同的引用类型
            if ((attr = strstr(strchr(typeEncoding, ','), ",C"))) // copy
            {
                return isSetter? (IMP)_setter_for_obj_copy_ : (IMP)_getter_for_obj_strong_;
            }
            else if ((attr = strstr(strchr(typeEncoding, ','), ",&"))) // strong/retain
            {
                return isSetter? (IMP)_setter_for_obj_strong_ : (IMP)_getter_for_obj_strong_;
            }
            else if ((attr = strstr(strchr(typeEncoding, ','), ",W"))) // weak
            {
                return isSetter? (IMP)_setter_for_obj_weak_ : (IMP)_getter_for_obj_weak_;
            }
            else // 没有指明就使用 strong
            {
                return isSetter? (IMP)_setter_for_obj_strong_ : (IMP)_getter_for_obj_strong_;
            }
        } break;
        case ':': // SEL，selector，本质上是一个结构体指针
        {
            return isSetter? (IMP)_setter_for_sel_ : (IMP)_getter_for_sel_;
        } break;
            
        /* 参数在压栈时是需要在编译期判断参数大小，大块数据类型超过了栈寄存器大小时，需要多寄存器联用，这需要编译期操作或者在汇编层面处理，
         * 在OC无法用一个IMP适配全部情况，所以这里返回nil。在-forwardInvocation: 去判断实现
         */
        case '{': // struct 结构体类型
        {
            return nil;
        } break;
        case '[': // array 数组
        {
            return nil;
        }
        case '(': // union 联合体类型
        {
            return nil;
        } break;
        default:
            break;
    }
    assert("未找到IMP");
    return nil;
}

@implementation CBModel

#pragma mark - selector 映射 属性名
static NSMutableDictionary<NSString*, NSMutableDictionary<NSString*, NSString*>*>* _classDynamicSel2Props;
+ (NSMutableDictionary<NSString *,NSString *> *)_dySel2Props {
    if (_classDynamicSel2Props == nil) {
        _classDynamicSel2Props = [NSMutableDictionary dictionary];
    }
    NSString* className = NSStringFromClass(self);
    if (!_classDynamicSel2Props[className]) {
        _classDynamicSel2Props[className] = [NSMutableDictionary dictionary];
    }
    
    return _classDynamicSel2Props[className];
}

+ (NSString* _Nullable)propNameForSel:(SEL)sel {
    return [self propNameForSelector:NSStringFromSelector(sel)];
}

+ (NSString *)propNameForSelector:(NSString *)selector {
    Class cls = self;
    NSString* propName = nil;
    do {
        propName = [cls _dySel2Props][selector];
    } while (propName == nil && (cls = [cls superclass]) != CBModel.class);
    
    return propName;
}

+ (void)setPropName:(NSString*)propName forSelector:(NSString*)selector {
    [self _dySel2Props][selector] = propName;
}

#pragma mark - 属性映射表
@synthesize sDynamicProperties = _sDynamicProperties;
/// 强引用映射表
- (NSMutableDictionary<NSString*, id> *)sDynamicProperties {
    if (_sDynamicProperties == nil) {
        _sDynamicProperties = [NSMutableDictionary dictionary];
    }
    return _sDynamicProperties;
}

@synthesize wDynamicProperties = _wDynamicProperties;
/// 弱引用映射表
- (NSMapTable<NSString*, id> *)wDynamicProperties {
    if (_wDynamicProperties == nil) {
        _wDynamicProperties = [NSMapTable strongToWeakObjectsMapTable];
    }
    return _wDynamicProperties;
}

#pragma mark - 动态实现方法
+ (BOOL)resolveInstanceMethod:(SEL)sel {
    
    if (![self isSubclassOfClass:CBModel.class]) {
        return [super resolveInstanceMethod:sel];
    }
    
    BOOL resolve = NO;
    
    Class cls = self;
    NSString* targetSelName = NSStringFromSelector(sel);
    do {
        uint propCount;
        objc_property_t *propList = class_copyPropertyList(cls, &propCount);
        objc_property_t curProp;
        for (int j = 0; j < propCount; j++) {
            curProp = propList[j];
            // 判断是不是动态属性，dynamic 修饰
            char* attrValue = property_copyAttributeValue(curProp, "D");
            free(attrValue); if (attrValue == NULL) { continue; } attrValue = NULL;
            
            // 提取属性名
            const char* propName = property_getName(curProp);
            NSString* targetPropName = [NSString stringWithUTF8String:propName];
            
            { // getter处理
                // 提取属性的getter方法名
                NSString* propGetterName = nil; {
                    attrValue = property_copyAttributeValue(curProp, "G");
                    if (attrValue) {
                        // 自定义的getter方法名
                        propGetterName = [NSString stringWithFormat:@"%s", attrValue];
                        free(attrValue); attrValue = NULL;
                    } else {
                        // 默认的getter方法名
                        propGetterName = [NSString stringWithFormat:@"%s", propName];
                    }
                }
                // 目标方法名跟当前属性的getter方法名一致，则动态添加方法
                if ([targetSelName isEqualToString:propGetterName]) {
                    attrValue = property_copyAttributeValue(curProp, "T");
                    const char* getterTypes = [NSString stringWithFormat:@"%s:", attrValue].UTF8String;
                    free(attrValue); attrValue = NULL;
                    // 动态添加方法实现
                    IMP impForProp = imp_for_property(NO, property_getAttributes(curProp));
                    if (![cls propNameForSelector:propGetterName] &&
                        getterTypes &&
                        impForProp &&
                        class_addMethod(cls, sel, impForProp, getterTypes)) {
                        [cls setPropName:targetPropName
                             forSelector:propGetterName];
                        resolve = YES;
                        break;
                    }
                }
            }
            
            { // setter处理
                // 提取属性的setter方法名
                NSString* propSetterName = nil; {
                    attrValue = property_copyAttributeValue(curProp, "S");
                    if (attrValue) {
                        // 自定义的setter方法名
                        propSetterName = [NSString stringWithFormat:@"%s", attrValue];
                        free(attrValue); attrValue = NULL;
                    }
                    else {
                        // 默认的setter方法名
                        propSetterName = [NSString stringWithFormat:@"set%c%s:", propName[0] & ~0x20, propName+1];
                    }
                }
                // 目标方法名跟当前属性的setter方法名一致，则动态添加方法
                if ([targetSelName isEqualToString:propSetterName]) {
                    attrValue = property_copyAttributeValue(curProp, "T");
                    const char* setterTypes = [NSString stringWithFormat:@"v:%s:", attrValue].UTF8String;
                    free(attrValue); attrValue = NULL;
                    // 动态添加方法实现
                    IMP impForProp = imp_for_property(YES, property_getAttributes(curProp));
                    if (![cls propNameForSelector:propSetterName] &&
                        setterTypes &&
                        impForProp &&
                        class_addMethod(cls, sel, impForProp, setterTypes)) {
                        [cls setPropName:targetPropName
                             forSelector:propSetterName];
                        resolve = YES;
                        break;
                    }
                }
            }
        }
        // 释放属性列表
        free(propList); propList = NULL;
        if (resolve) { return YES; }
    } while ((cls = [cls superclass]) != CBModel.class);
    
    return [super resolveInstanceMethod:sel];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    BOOL resolve = NO;
    
    Class cls = self.class;
    NSString* targetSelName = NSStringFromSelector(anInvocation.selector);
    do {
        uint propCount;
        objc_property_t *propList = class_copyPropertyList(cls, &propCount);
        objc_property_t curProp;
        for (int j = 0; j < propCount; j++) {
            curProp = propList[j];
            // 判断是不是动态属性，dynamic 修饰
            char* attrValue = property_copyAttributeValue(curProp, "D");
            free(attrValue); if (attrValue == NULL) { continue; } attrValue = NULL;
            
            // 提取属性名
            const char* propName = property_getName(curProp);
            NSString* targetPropName = [NSString stringWithUTF8String:propName];
            
            { // getter处理
                // 提取属性的getter方法名
                NSString* propGetterName = nil; {
                    attrValue = property_copyAttributeValue(curProp, "G");
                    if (attrValue) {
                        // 自定义的getter方法名
                        propGetterName = [NSString stringWithFormat:@"%s", attrValue];
                        free(attrValue); attrValue = NULL;
                    } else {
                        // 默认的getter方法名
                        propGetterName = [NSString stringWithFormat:@"%s", propName];
                    }
                }
                // 目标方法名跟当前属性的getter方法名一致
                if ([targetSelName isEqualToString:propGetterName]) {
                    NSUInteger retSize = anInvocation.methodSignature.methodReturnLength;
                    NSValue* value = self.sDynamicProperties[targetPropName];
                    if (value) {
                        void* buff = alloca(retSize);
                        memset(buff, 0, retSize);
                        [value getValue:buff size:retSize];
                        [anInvocation setReturnValue:buff];
                        
                        resolve = YES;
                        break;
                    }
                }
            }
            
            { // setter处理
                // 提取属性的setter方法名
                NSString* propSetterName = nil; {
                    attrValue = property_copyAttributeValue(curProp, "S");
                    if (attrValue) {
                        // 自定义的setter方法名
                        propSetterName = [NSString stringWithFormat:@"%s", attrValue];
                        free(attrValue); attrValue = NULL;
                    }
                    else {
                        // 默认的setter方法名
                        propSetterName = [NSString stringWithFormat:@"set%c%s:", propName[0] & ~0x20, propName+1];
                    }
                }
                // 目标方法名跟当前属性的setter方法名一致
                if ([targetSelName isEqualToString:propSetterName]) {
                    const char* argTypeCode = [anInvocation.methodSignature getArgumentTypeAtIndex:2];
                    NSUInteger argSize = 0;
                    NSGetSizeAndAlignment(argTypeCode, &argSize, NULL);
                    void* buff = alloca(argSize);
                    [anInvocation getArgument:buff atIndex:2];
                    self.sDynamicProperties[targetPropName] = [NSValue value:buff withObjCType:argTypeCode];
                    
                    resolve = YES;
                    break;
                }
            }
        }
        
        // 释放属性列表
        free(propList); propList = NULL;
        if (resolve) { return; }
    } while ((cls = [cls superclass]) != CBModel.class);
    
    // 以上逻辑都没有完成处理，那就交由父类的方法出处理
    [super forwardInvocation:anInvocation];
}

@end
