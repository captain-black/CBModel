//
//  CBModel.m
//  CBModel
//
//  Created by Captain Black on 2023/7/14.
//

#import "CBModel.h"

#import <objc/runtime.h>

@interface CBModel ()
+ (NSString* _Nullable)propNameForSel:(SEL)sel;
+ (NSString* _Nullable)propNameForSelector:(NSString*)selectorName;
+ (NSLock*)lockForProperty:(NSString*)propName inInstance:(CBModel*)instance;
@end

#pragma mark - nonatomic 非原子性的IMP实现
#define IMP_FOR_TYPE(typeName, _TYPE_)                                                  \
static _TYPE_ _getter_for_##typeName##_(CBModel* self, SEL _cmd) {                      \
    NSString* p = [[self class] propNameForSel:_cmd];                                   \
    unsigned int size = sizeof(_TYPE_);                                                 \
    void* value = alloca(size);                                                         \
    memset(value, 0, size);                                                             \
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
    [self willChangeValueForKey:p];                                                     \
    self.sDynamicProperties[p] = [NSValue value:&value withObjCType:@encode(_TYPE_)];   \
    [self didChangeValueForKey:p];                                                      \
}


static id _getter_for_obj_strong_(CBModel* self, SEL _cmd) {
    NSString* p = [[self class] propNameForSel:_cmd];
    return self.sDynamicProperties[p];
}

static void _setter_for_obj_strong_(CBModel* self, SEL _cmd, id value) {
    NSString* p = [[self class] propNameForSel:_cmd];
    [self willChangeValueForKey:p];
    self.sDynamicProperties[p] = value;
    [self didChangeValueForKey:p];
}

static void _setter_for_obj_copy_(CBModel* self, SEL _cmd, id value) {
    NSString* p = [[self class] propNameForSel:_cmd];
    [self willChangeValueForKey:p];
    self.sDynamicProperties[p] = [value copy];
    [self didChangeValueForKey:p];
}

static id _getter_for_obj_weak_(CBModel* self, SEL _cmd) {
    NSString* p = [[self class] propNameForSel:_cmd];
    return [self.wDynamicProperties objectForKey:p];
}

static void _setter_for_obj_weak_(CBModel* self, SEL _cmd, id value) {
    NSString* p = [[self class] propNameForSel:_cmd];
    [self willChangeValueForKey:p];
    [self.wDynamicProperties setObject:value
                                forKey:p];
    [self didChangeValueForKey:p];
}

static void* _getter_for_pointer_(CBModel* self, SEL _cmd) {
    NSString* p = [[self class] propNameForSel:_cmd];
    NSValue* val = [self.sDynamicProperties objectForKey:p];
    return [val pointerValue];
}

static void _setter_for_pointer_(CBModel* self, SEL _cmd, const void* value) {
    NSString* p = [[self class] propNameForSel:_cmd];
    NSValue* val = [NSValue valueWithPointer:value];
    [self willChangeValueForKey:p];
    [self.sDynamicProperties setObject:val
                                forKey:p];
    [self didChangeValueForKey:p];
}

static void* _getter_for_sel_(CBModel* self, SEL _cmd) {
    NSString* p = [[self class] propNameForSel:_cmd];
    NSValue* val = [self.sDynamicProperties objectForKey:p];
    return (__bridge void*)[val nonretainedObjectValue];
}

static void _setter_for_sel_(CBModel* self, SEL _cmd, __unsafe_unretained id value) {
    NSString* p = [[self class] propNameForSel:_cmd];
    [self willChangeValueForKey:p];
    NSValue* val = [NSValue valueWithNonretainedObject:value];
    [self.sDynamicProperties setObject:val
                                forKey:p];
    [self didChangeValueForKey:p];
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

#pragma mark - Atomic 原子性的IMP实现
#define IMP_FOR_TYPE_ATOMIC(typeName, _TYPE_)                                           \
static _TYPE_ _getter_for_atomic_##typeName##_(CBModel* self, SEL _cmd) {               \
    NSString* p = [[self class] propNameForSel:_cmd];                                   \
    NSLock* lock = [[self class] lockForProperty:p inInstance:self];                    \
    [lock lock];                                                                        \
    unsigned int size = sizeof(_TYPE_);                                                 \
    void* value = alloca(size);                                                         \
    memset(value, 0, size);                                                             \
    if (@available(iOS 11.0, *)) {                                                      \
        [self.sDynamicProperties[p] getValue:value size:size];                          \
    } else {                                                                            \
        [self.sDynamicProperties[p] getValue:value];                                    \
    }                                                                                   \
    [lock unlock];                                                                      \
    return *(_TYPE_*)value;                                                             \
}                                                                                       \
\
static void _setter_for_atomic_##typeName##_(CBModel* self, SEL _cmd, _TYPE_ value) {   \
    NSString* p = [[self class] propNameForSel:_cmd];                                   \
    NSLock* lock = [[self class] lockForProperty:p inInstance:self];                    \
    [lock lock];                                                                        \
    [self willChangeValueForKey:p];                                                     \
    self.sDynamicProperties[p] = [NSValue value:&value withObjCType:@encode(_TYPE_)];   \
    [self didChangeValueForKey:p];                                                      \
    [lock unlock];                                                                      \
}

static id _getter_for_atomic_obj_strong_(CBModel* self, SEL _cmd) {
    NSString* p = [[self class] propNameForSel:_cmd];
    NSLock* lock = [[self class] lockForProperty:p inInstance:self];
    [lock lock];
    id value = self.sDynamicProperties[p];
    [lock unlock];
    return value;
}

static void _setter_for_atomic_obj_strong_(CBModel* self, SEL _cmd, id value) {
    NSString* p = [[self class] propNameForSel:_cmd];
    NSLock* lock = [[self class] lockForProperty:p inInstance:self];
    [lock lock];
    [self willChangeValueForKey:p];
    self.sDynamicProperties[p] = value;
    [self didChangeValueForKey:p];
    [lock unlock];
}

static void _setter_for_atomic_obj_copy_(CBModel* self, SEL _cmd, id value) {
    NSString* p = [[self class] propNameForSel:_cmd];
    NSLock* lock = [[self class] lockForProperty:p inInstance:self];
    [lock lock];
    [self willChangeValueForKey:p];
    self.sDynamicProperties[p] = [value copy];
    [self didChangeValueForKey:p];
    [lock unlock];
}

static id _getter_for_atomic_obj_weak_(CBModel* self, SEL _cmd) {
    NSString* p = [[self class] propNameForSel:_cmd];
    NSLock* lock = [[self class] lockForProperty:p inInstance:self];
    [lock lock];
    id value = [self.wDynamicProperties objectForKey:p];
    [lock unlock];
    return value;
}

static void _setter_for_atomic_obj_weak_(CBModel* self, SEL _cmd, id value) {
    NSString* p = [[self class] propNameForSel:_cmd];
    NSLock* lock = [[self class] lockForProperty:p inInstance:self];
    [lock lock];
    [self willChangeValueForKey:p];
    [self.wDynamicProperties setObject:value forKey:p];
    [self didChangeValueForKey:p];
    [lock unlock];
}

static void* _getter_for_atomic_pointer_(CBModel* self, SEL _cmd) {
    NSString* p = [[self class] propNameForSel:_cmd];
    NSLock* lock = [[self class] lockForProperty:p inInstance:self];
    [lock lock];
    NSValue* val = [self.sDynamicProperties objectForKey:p];
    void* result = [val pointerValue];
    [lock unlock];
    return result;
}

static void _setter_for_atomic_pointer_(CBModel* self, SEL _cmd, const void* value) {
    NSString* p = [[self class] propNameForSel:_cmd];
    NSLock* lock = [[self class] lockForProperty:p inInstance:self];
    [lock lock];
    [self willChangeValueForKey:p];
    NSValue* val = [NSValue valueWithPointer:value];
    [self.sDynamicProperties setObject:val forKey:p];
    [self didChangeValueForKey:p];
    [lock unlock];
}

static void* _getter_for_atomic_sel_(CBModel* self, SEL _cmd) {
    NSString* p = [[self class] propNameForSel:_cmd];
    NSLock* lock = [[self class] lockForProperty:p inInstance:self];
    [lock lock];
    NSValue* val = [self.sDynamicProperties objectForKey:p];
    void* result = (__bridge void*)[val nonretainedObjectValue];
    [lock unlock];
    return result;
}

static void _setter_for_atomic_sel_(CBModel* self, SEL _cmd, __unsafe_unretained id value) {
    NSString* p = [[self class] propNameForSel:_cmd];
    NSLock* lock = [[self class] lockForProperty:p inInstance:self];
    [lock lock];
    [self willChangeValueForKey:p];
    NSValue* val = [NSValue valueWithNonretainedObject:value];
    [self.sDynamicProperties setObject:val forKey:p];
    [self didChangeValueForKey:p];
    [lock unlock];
}

IMP_FOR_TYPE_ATOMIC(char, char);
IMP_FOR_TYPE_ATOMIC(short, short);
IMP_FOR_TYPE_ATOMIC(int, int);
IMP_FOR_TYPE_ATOMIC(long, long);
IMP_FOR_TYPE_ATOMIC(longLong, long long);
IMP_FOR_TYPE_ATOMIC(unsignedChar, unsigned char);
IMP_FOR_TYPE_ATOMIC(unsignedInt, unsigned int);
IMP_FOR_TYPE_ATOMIC(unsignedShort, unsigned short);
IMP_FOR_TYPE_ATOMIC(unsignedLong, unsigned long);
IMP_FOR_TYPE_ATOMIC(unsignedLongLong, unsigned long long);
IMP_FOR_TYPE_ATOMIC(float, float);
IMP_FOR_TYPE_ATOMIC(double, double);
IMP_FOR_TYPE_ATOMIC(longDouble, long double);
IMP_FOR_TYPE_ATOMIC(bool, bool);

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
 ^：表示指针类型
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
static IMP imp_for_property(BOOL isSetter, BOOL isAtomic, const char* propAttributes) {
    char *typeEncoding = strchr(propAttributes, 'T');
    switch (*(typeEncoding+1)) {
        case 'c': // char
        {
            return isSetter? (isAtomic? (IMP)_setter_for_atomic_char_ : (IMP)_setter_for_char_) : (isAtomic? (IMP)_getter_for_atomic_char_ : (IMP)_getter_for_char_);
        } break;
        case 'i': // int
        {
            return isSetter? (isAtomic? (IMP)_setter_for_atomic_int_ : (IMP)_setter_for_int_) : (isAtomic? (IMP)_getter_for_atomic_int_ : (IMP)_getter_for_int_);
        } break;
        case 's': // short
        {
            return isSetter? (isAtomic? (IMP)_setter_for_atomic_short_ : (IMP)_setter_for_short_) : (isAtomic? (IMP)_getter_for_atomic_short_ : (IMP)_getter_for_short_);
        } break;
        case 'l': // long
        {
            return isSetter? (isAtomic? (IMP)_setter_for_atomic_long_ : (IMP)_setter_for_long_) : (isAtomic? (IMP)_getter_for_atomic_long_ : (IMP)_getter_for_long_);
        } break;
        case 'q': // long long
        {
            return isSetter? (isAtomic? (IMP)_setter_for_atomic_longLong_ : (IMP)_setter_for_longLong_) : (isAtomic? (IMP)_getter_for_atomic_longLong_ : (IMP)_getter_for_longLong_);
        } break;
        case 'C': // unsigned char
        {
            return isSetter? (isAtomic? (IMP)_setter_for_atomic_unsignedChar_ : (IMP)_setter_for_unsignedChar_) : (isAtomic? (IMP)_getter_for_atomic_unsignedChar_ : (IMP)_getter_for_unsignedChar_);
        } break;
        case 'I': // unsigned int
        {
            return isSetter? (isAtomic? (IMP)_setter_for_atomic_unsignedInt_ : (IMP)_setter_for_unsignedInt_) : (isAtomic? (IMP)_getter_for_atomic_unsignedInt_ : (IMP)_getter_for_unsignedInt_);
        } break;
        case 'S': // unsigned short
        {
            return isSetter? (isAtomic? (IMP)_setter_for_atomic_unsignedShort_ : (IMP)_setter_for_unsignedShort_) : (isAtomic? (IMP)_getter_for_atomic_unsignedShort_ : (IMP)_getter_for_unsignedShort_);
        } break;
        case 'L': // unsigned long
        {
            return isSetter? (isAtomic? (IMP)_setter_for_atomic_unsignedLong_ : (IMP)_setter_for_unsignedLong_) : (isAtomic? (IMP)_getter_for_atomic_unsignedLong_ : (IMP)_getter_for_unsignedLong_);
        } break;
        case 'Q': // unsigned long long
        {
            return isSetter? (isAtomic? (IMP)_setter_for_atomic_unsignedLongLong_ : (IMP)_setter_for_unsignedLongLong_) : (isAtomic? (IMP)_getter_for_atomic_unsignedLongLong_ : (IMP)_getter_for_unsignedLongLong_);
        } break;
        case 'f': // float
        {
            return isSetter? (isAtomic? (IMP)_setter_for_atomic_float_ : (IMP)_setter_for_float_) : (isAtomic? (IMP)_getter_for_atomic_float_ : (IMP)_getter_for_float_);
        } break;
        case 'd': // double
        {
            return isSetter? (isAtomic? (IMP)_setter_for_atomic_double_ : (IMP)_setter_for_double_) : (isAtomic? (IMP)_getter_for_atomic_double_ : (IMP)_getter_for_double_);
        } break;
        case 'D': // long double
        {
            return isSetter? (isAtomic? (IMP)_setter_for_atomic_longDouble_ : (IMP)_setter_for_longDouble_) : (isAtomic? (IMP)_getter_for_atomic_longDouble_ : (IMP)_getter_for_longDouble_);
        } break;
        case 'B': // BOOL
        {
            return isSetter? (isAtomic? (IMP)_setter_for_atomic_bool_ : (IMP)_setter_for_bool_) : (isAtomic? (IMP)_getter_for_atomic_bool_ : (IMP)_getter_for_bool_);
        } break;
        case '^': // Pointer
        {
            return isSetter? (isAtomic? (IMP)_setter_for_atomic_pointer_ : (IMP)_setter_for_pointer_) : (isAtomic? (IMP)_getter_for_atomic_pointer_ : (IMP)_getter_for_pointer_);
        } break;
        case '@': // NSObject
        case '#': // class，class本质上也是一个NSObject，所以getter、setter可以共用
        {
            char* attr;
            // OC 对象属性还要区分不同的引用类型
            if ((attr = strstr(strchr(typeEncoding, ','), ",C"))) // copy
            {
                return isSetter? (isAtomic? (IMP)_setter_for_atomic_obj_copy_ : (IMP)_setter_for_obj_copy_) : (isAtomic? (IMP)_getter_for_atomic_obj_strong_ : (IMP)_getter_for_obj_strong_);
            }
            else if ((attr = strstr(strchr(typeEncoding, ','), ",&"))) // strong/retain
            {
                return isSetter? (isAtomic? (IMP)_setter_for_atomic_obj_strong_ : (IMP)_setter_for_obj_strong_) : (isAtomic? (IMP)_getter_for_atomic_obj_strong_ : (IMP)_getter_for_obj_strong_);
            }
            else if ((attr = strstr(strchr(typeEncoding, ','), ",W"))) // weak
            {
                return isSetter? (isAtomic? (IMP)_setter_for_atomic_obj_weak_ : (IMP)_setter_for_obj_weak_) : (isAtomic? (IMP)_getter_for_atomic_obj_weak_ : (IMP)_getter_for_obj_weak_);
            }
            else // 没有指明就使用 strong
            {
                return isSetter? (isAtomic? (IMP)_setter_for_atomic_obj_strong_ : (IMP)_setter_for_obj_strong_) : (isAtomic? (IMP)_getter_for_atomic_obj_strong_ : (IMP)_getter_for_obj_strong_);
            }
        } break;
        case ':': // SEL，selector，本质上是一个结构体指针
        {
            return isSetter? (isAtomic? (IMP)_setter_for_atomic_sel_ : (IMP)_setter_for_sel_) : (isAtomic? (IMP)_getter_for_atomic_sel_ : (IMP)_getter_for_sel_);
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

#pragma mark - KVC 支持
- (id)valueForUndefinedKey:(NSString *)key {
    id value = self.sDynamicProperties[key];
    if (value == nil) {
        value = [self.wDynamicProperties objectForKey:key];
    }
    
    id retValue = nil;
    if ([value isKindOfClass:[NSValue class]] && ![value isKindOfClass:[NSNumber class]]) {
        objc_property_t prop = class_getProperty([self class], key.UTF8String);
        if (prop) {
            NSValue *v = (NSValue *)value;
            const char *type = [v objCType];
            if (type && type[0] != '@') {
                NSUInteger size;
                NSGetSizeAndAlignment(type, &size, NULL);
                void *buffer = malloc(size);
                if (@available(iOS 11.0, *)) {
                    [v getValue:buffer size:size];
                } else {
                    [v getValue:buffer];
                }
                
                switch (type[0]) {
                    case 'c': retValue = @(*(char*)buffer); break;
                    case 'i': retValue = @(*(int*)buffer); break;
                    case 's': retValue = @(*(short*)buffer); break;
                    case 'l': retValue = @(*(long*)buffer); break;
                    case 'q': retValue = @(*(long long*)buffer); break;
                    case 'C': retValue = @(*(unsigned char*)buffer); break;
                    case 'I': retValue = @(*(unsigned int*)buffer); break;
                    case 'S': retValue = @(*(unsigned short*)buffer); break;
                    case 'L': retValue = @(*(unsigned long*)buffer); break;
                    case 'Q': retValue = @(*(unsigned long long*)buffer); break;
                    case 'f': retValue = @(*(float*)buffer); break;
                    case 'd': retValue = @(*(double*)buffer); break;
                    // long double 类型需要特殊处理，这类型编译器无法装箱成NSNumber的，KVC要用NSValue来装，那这里读取也应该用NSValue的方式
                    case 'D': retValue = [NSValue valueWithBytes:buffer objCType:type]; break; 
                    case 'B': retValue = @(*(BOOL*)buffer); break;
                    default:
                        /* 对于指针、数组、结构体、联合体等复杂类型，无法直接用 NSNumber 装箱，
                         * 这里直接把入参 id 值当对象指针传进去，由调用端保证类型匹配。
                         * 若实际类型不符，运行期会崩溃，属于调用者责任。 */
                        retValue = v;
                }
                free(buffer);
            }
        }
    } else {
        retValue = value;
    }
    
    return retValue;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    objc_property_t prop = class_getProperty([self class], key.UTF8String);
    if (prop) {
        // 通过prop拿到对应的setter，调用setter
        char *setterAttr = property_copyAttributeValue(prop, "S");
        NSString *setterName = setterAttr ? [NSString stringWithUTF8String:setterAttr] : [NSString stringWithFormat:@"set%c%s:", key.UTF8String[0] & ~0x20, key.UTF8String + 1];
        free(setterAttr);
        
        SEL setterSel = NSSelectorFromString(setterName);
        if ([self respondsToSelector:setterSel]) {
            NSMethodSignature *sig = [self methodSignatureForSelector:setterSel];
            NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
            [inv setTarget:self];
            [inv setSelector:setterSel];
            // 根据属性类型把 value 转成对应 C 类型，再 setArgument
            char *typeAttr = property_copyAttributeValue(prop, "T");
            if (typeAttr) {
                char encoding = typeAttr[0];
                switch (encoding) {
                    case 'c': { char arg = [value charValue];     [inv setArgument:&arg atIndex:2]; break; }
                    case 'i': { int arg = [value intValue];       [inv setArgument:&arg atIndex:2]; break; }
                    case 's': { short arg = [value shortValue];   [inv setArgument:&arg atIndex:2]; break; }
                    case 'l': { long arg = [value longValue];     [inv setArgument:&arg atIndex:2]; break; }
                    case 'q': { long long arg = [value longLongValue];            [inv setArgument:&arg atIndex:2]; break; }
                    case 'C': { unsigned char arg = [value unsignedCharValue];    [inv setArgument:&arg atIndex:2]; break; }
                    case 'I': { unsigned int arg = [value unsignedIntValue];      [inv setArgument:&arg atIndex:2]; break; }
                    case 'S': { unsigned short arg = [value unsignedShortValue];  [inv setArgument:&arg atIndex:2]; break; }
                    case 'L': { unsigned long arg = [value unsignedLongValue];    [inv setArgument:&arg atIndex:2]; break; }
                    case 'Q': { unsigned long long arg = [value unsignedLongLongValue]; [inv setArgument:&arg atIndex:2]; break; }
                    case 'f': { float arg = [value floatValue];   [inv setArgument:&arg atIndex:2]; break; }
                    case 'd': { double arg = [value doubleValue]; [inv setArgument:&arg atIndex:2]; break; }
                    case 'D': {
                        long double arg;
                        if (@available(iOS 11.0, *)) {
                            [value getValue:&arg size:sizeof(long double)];
                        } else {
                            [value getValue:&arg];
                        }
                        [inv setArgument:&arg atIndex:2];
                        break;
                    }
                    case 'B': { BOOL arg = [value boolValue];     [inv setArgument:&arg atIndex:2]; break; }
                    default: {
                        [inv setArgument:&value atIndex:2];
                        break;
                    }
                }
                free(typeAttr);
            } else {
                [inv setArgument:&value atIndex:2];
            }
            
            return [inv invoke];
        }
    }
    
    [super setValue:value forUndefinedKey:key];
}

#pragma mark - KVO 支持
+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    return YES;
}

#pragma mark - NSCoding 支持
- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        uint propCount;
        objc_property_t *propList = class_copyPropertyList([self class], &propCount);
        for (uint i = 0; i < propCount; i++) {
            objc_property_t prop = propList[i];
            char* attrValue = property_copyAttributeValue(prop, "D");
            free(attrValue);
            if (attrValue == NULL) {
                continue;
            }
            
            const char* propName = property_getName(prop);
            NSString* key = [NSString stringWithUTF8String:propName];
            
            if ([coder containsValueForKey:key]) {
                id value = [coder decodeObjectForKey:key];
                if (value) {
                    self.sDynamicProperties[key] = value;
                }
            }
        }
        free(propList);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [self.sDynamicProperties enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
        [coder encodeObject:value forKey:key];
    }];
}

#pragma mark - NSCopying 支持
- (id)copyWithZone:(NSZone *)zone {
    CBModel *copy = [[[self class] allocWithZone:zone] init];
    if (copy) {
        [self.sDynamicProperties enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
            if ([value conformsToProtocol:@protocol(NSCopying)]) {
                copy.sDynamicProperties[key] = [value copyWithZone:zone];
            } else {
                copy.sDynamicProperties[key] = value;
            }
        }];
    }
    return copy;
}

#pragma mark - Description 支持
- (NSString *)_formatValue:(NSValue *)value withType:(const char *)typeEncoding {
    if (value == nil || typeEncoding == NULL) {
        return @"(nil)";
    }
    
    switch (typeEncoding[0]) {
        case 'c': { char v; [value getValue:&v]; return [NSString stringWithFormat:@"%d", v]; }
        case 'i': { int v; [value getValue:&v]; return [NSString stringWithFormat:@"%d", v]; }
        case 's': { short v; [value getValue:&v]; return [NSString stringWithFormat:@"%d", v]; }
        case 'l': { long v; [value getValue:&v]; return [NSString stringWithFormat:@"%ld", v]; }
        case 'q': { long long v; [value getValue:&v]; return [NSString stringWithFormat:@"%lld", v]; }
        case 'C': { unsigned char v; [value getValue:&v]; return [NSString stringWithFormat:@"%u", v]; }
        case 'I': { unsigned int v; [value getValue:&v]; return [NSString stringWithFormat:@"%u", v]; }
        case 'S': { unsigned short v; [value getValue:&v]; return [NSString stringWithFormat:@"%u", v]; }
        case 'L': { unsigned long v; [value getValue:&v]; return [NSString stringWithFormat:@"%lu", v]; }
        case 'Q': { unsigned long long v; [value getValue:&v]; return [NSString stringWithFormat:@"%llu", v]; }
        case 'f': { float v; [value getValue:&v]; return [NSString stringWithFormat:@"%f", v]; }
        case 'd': { double v; [value getValue:&v]; return [NSString stringWithFormat:@"%f", v]; }
        case 'B': { BOOL v; [value getValue:&v]; return v ? @"YES" : @"NO"; }
        case '@': {
            if ([value isKindOfClass:[NSValue class]]) {
                return [(id)value description];
            }
            return [value description];
        }
        default: return [value description];
    }
}

- (NSString *)description {
    NSMutableString *desc = [NSMutableString stringWithFormat:@"<%@: %p>", NSStringFromClass([self class]), self];
    
    uint propCount;
    objc_property_t *propList = class_copyPropertyList([self class], &propCount);
    for (uint i = 0; i < propCount; i++) {
        objc_property_t prop = propList[i];
        
        char* attrValue = property_copyAttributeValue(prop, "D");
        if (attrValue == NULL) {
            free(attrValue);
            continue;
        }
        free(attrValue);
        
        const char* propName = property_getName(prop);
        NSString* key = [NSString stringWithUTF8String:propName];
        
        char* typeEncoding = property_copyAttributeValue(prop, "T");
        id storedValue = self.sDynamicProperties[key];
        
        if (storedValue && typeEncoding) {
            NSString *valueStr;
            if (typeEncoding[0] == '@') {
                valueStr = [storedValue description];
            } else {
                valueStr = [self _formatValue:storedValue withType:typeEncoding];
            }
            [desc appendFormat:@"\n  %@ = %@", key, valueStr];
        }
        free(typeEncoding);
    }
    free(propList);
    
    return desc;
}

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

@synthesize propertyLocks = _propertyLocks;
/// 属性锁映射表
- (NSMutableDictionary<NSString*, NSLock*> *)propertyLocks {
    if (_propertyLocks == nil) {
        _propertyLocks = [NSMutableDictionary dictionary];
    }
    return _propertyLocks;
}

#pragma mark - 锁管理
static NSLock *_globalLockForLockCreation = nil;
+ (NSLock*)lockForProperty:(NSString*)propName inInstance:(CBModel*)instance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _globalLockForLockCreation = [[NSLock alloc] init];
    });
    
    [_globalLockForLockCreation lock];
    NSMutableDictionary* locks = instance.propertyLocks;
    NSLock* lock = locks[propName];
    if (lock == nil) {
        lock = [[NSLock alloc] init];
        locks[propName] = lock;
    }
    [_globalLockForLockCreation unlock];
    return lock;
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
                    
                    // 判断是否为 atomic 属性（属性编码中不包含 'N'）
                    attrValue = property_copyAttributeValue(curProp, "N");
                    BOOL isAtomic = (attrValue == NULL);
                    free(attrValue); attrValue = NULL;
                    
                    // 动态添加方法实现
                    IMP impForProp = imp_for_property(NO, isAtomic, property_getAttributes(curProp));
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
                    
                    // 判断是否为 atomic 属性（属性编码中不包含 'N'）
                    attrValue = property_copyAttributeValue(curProp, "N");
                    BOOL isAtomic = (attrValue == NULL);
                    free(attrValue); attrValue = NULL;
                    
                    // 动态添加方法实现
                    IMP impForProp = imp_for_property(YES, isAtomic, property_getAttributes(curProp));
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
                    // 判断是否为 atomic 属性（属性编码中不包含 'N'）
                    attrValue = property_copyAttributeValue(curProp, "N");
                    BOOL isAtomic = (attrValue == NULL);
                    free(attrValue); attrValue = NULL;
                    
                    NSUInteger retSize = anInvocation.methodSignature.methodReturnLength;
                    
                    if (isAtomic) {
                        // atomic 属性需要加锁
                        NSLock* lock = [[self class] lockForProperty:targetPropName inInstance:self];
                        [lock lock];
                        NSValue* value = self.sDynamicProperties[targetPropName];
                        if (value) {
                            void* buff = alloca(retSize);
                            memset(buff, 0, retSize);
                            [value getValue:buff size:retSize];
                            [anInvocation setReturnValue:buff];
                        }
                        [lock unlock];
                        resolve = YES;
                        break;
                    } else {
                        // nonatomic 属性无需加锁
                        NSValue* value = self.sDynamicProperties[targetPropName];
                        if (value) {
                            void* buff = alloca(retSize);
                            memset(buff, 0, retSize);
                            [value getValue:buff size:retSize];
                            [anInvocation setReturnValue:buff];
                        }
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
                    // 判断是否为 atomic 属性（属性编码中不包含 'N'）
                    attrValue = property_copyAttributeValue(curProp, "N");
                    BOOL isAtomic = (attrValue == NULL);
                    free(attrValue); attrValue = NULL;
                    
                    const char* argTypeCode = [anInvocation.methodSignature getArgumentTypeAtIndex:2];
                    NSUInteger argSize = 0;
                    NSGetSizeAndAlignment(argTypeCode, &argSize, NULL);
                    void* buff = alloca(argSize);
                    [anInvocation getArgument:buff atIndex:2];
                    
                    if (isAtomic) {
                        // atomic 属性需要加锁
                        NSLock* lock = [[self class] lockForProperty:targetPropName inInstance:self];
                        [lock lock];
                        self.sDynamicProperties[targetPropName] = [NSValue value:buff withObjCType:argTypeCode];
                        [lock unlock];
                    } else {
                        // nonatomic 属性无需加锁
                        self.sDynamicProperties[targetPropName] = [NSValue value:buff withObjCType:argTypeCode];
                    }
                    
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
