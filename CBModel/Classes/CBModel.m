//
//  CBModel.m
//  CBModel
//
//  Created by Captain Black on 2023/7/14.
//

#import "CBModel.h"

#import <objc/runtime.h>
#import <os/lock.h>
#import <stdatomic.h>

#pragma mark - 属性槽（每实例每属性一个，替代共享容器）
/// 槽的存储语义（ensureSlotArray 时按属性编码解析确定）
typedef NS_ENUM(uint8_t, CBMPropStorage) {
    CBMPropStorageStrong = 0,   // strong/copy 对象 → _strongValue
    CBMPropStorageWeak,         // weak 对象 → _weakValue（ARC 自动置零）
    CBMPropStorageRaw,          // 标量/指针/SEL → _raw.bytes（裸字节，v1.4 2.5）
    CBMPropStorageBoxed,        // 结构体/联合体/C 数组 → _boxedValue（NSValue 装箱，大小不定）
};

/// 槽对象：迷你 ivar 容器。不同属性的槽互不共享任何结构 → 并发访问天然隔离，
/// 共享容器与实例级锁从热路径消失（v1.4 Phase 2 组件 B）。
@interface CBMPropertySlot : NSObject {
@public
    CBMPropStorage storage;     // 存储语义
    BOOL atomic;                // 是否为 atomic 属性（决定是否用 _lock）
    id __strong _strongValue;   // strong/copy 对象值
    id __weak _weakValue;       // weak 对象值（ARC 自动置零）
    NSValue *_boxedValue;       // 结构体/联合体/C 数组装箱值（ARC 自动管理）
    os_unfair_lock _lock;       // atomic 属性专用（per-instance，alloc 清零即有效）
    /// 裸字节存储：标量/指针/SEL（long double 最大 16 字节）。
    /// 统一用 memcpy 读写（无对齐要求、无严格别名问题），
    /// 仅 long long 成员用于把 union 对齐提到 8 字节（long double 需要）。
    union {
        unsigned char bytes[16];
        long long align;
    } _raw;
}
@end

/// 热路径查询结果：一次查表同时拿属性名（KVO key）与槽下标
typedef struct {
    __unsafe_unretained NSString *propName;  // 未命中 = nil
    NSInteger index;                         // 未命中 = -1
} CBMPropInfo;

// 前置声明：快查表查询函数与表类型（宏在文件前部展开，需在宏之前可见；
// 类方法声明在类扩展中对 C 函数不可见——[self 类方法] 按实例方法查找会报错，故用 C 函数）
struct CBMSelMap;
static inline CBMPropInfo CBMPropInfoForSel(Class cls, SEL sel);

@interface CBModel () {
    @public
    /// 槽数组：每实例定长（容量 = 类链 @dynamic 属性总数），_slotsReady 发布后只读
    NSMutableArray<CBMPropertySlot*> *_slotArray;
    /// 槽数组初始化完成标志：写 _slotArray → release store → acquire load 后读数组无竞争
    _Atomic(BOOL) _slotsReady;
    /// 初始化锁（alloc 清零即有效）：ensureSlotArray 的锁内双检
    os_unfair_lock _initLock;
}
- (void)ensureSlotArray;
/// 结构体/联合体属性首次转发时锁内注册表项（幂等），返回槽下标
- (NSInteger)ensureForwardedPropIndex:(Class)declaringClass
                                  sel:(SEL)sel
                             propName:(NSString *)propName
                            propIndex:(NSInteger)propIndex;
@end

#pragma mark - nonatomic 非原子性的IMP实现
/// 热路径公共前奏（getter 版）：快查 {propName, index} + 槽数组就绪检查。
/// 未命中（index < 0）理论不可能发生（IMP 存在 ⇒ 映射已发布，2.3 不变量），防御性返回零值。
#define CB_GETTER_PREAMBLE(_self_, _cmd_, _info_, _slot_, _missRet_)                      \
    CBMPropInfo _info_ = CBMPropInfoForSel(object_getClass(_self_), _cmd_);              \
    if (__builtin_expect(_info_.index < 0, 0)) { return _missRet_; }                     \
    if (__builtin_expect(!atomic_load_explicit(&(_self_)->_slotsReady, memory_order_acquire), 0)) { \
        [(_self_) ensureSlotArray];                                                      \
    }                                                                                    \
    CBMPropertySlot* _slot_ = (_self_)->_slotArray[_info_.index];

/// 热路径公共前奏（setter 版）
#define CB_SETTER_PREAMBLE(_self_, _cmd_, _info_, _slot_)                                 \
    CBMPropInfo _info_ = CBMPropInfoForSel(object_getClass(_self_), _cmd_);              \
    if (__builtin_expect(_info_.index < 0, 0)) { return; }                               \
    if (__builtin_expect(!atomic_load_explicit(&(_self_)->_slotsReady, memory_order_acquire), 0)) { \
        [(_self_) ensureSlotArray];                                                      \
    }                                                                                    \
    CBMPropertySlot* _slot_ = (_self_)->_slotArray[_info_.index];

#define IMP_FOR_TYPE(typeName, _TYPE_)                                                  \
static _TYPE_ _getter_for_##typeName##_(CBModel* self, SEL _cmd) {                      \
    CB_GETTER_PREAMBLE(self, _cmd, info, slot, (_TYPE_)0)                                \
    _TYPE_ value;                                                                       \
    memcpy(&value, slot->_raw.bytes, sizeof(_TYPE_));   /* 未写过的槽为全零（alloc 清零） */ \
    return value;                                                                       \
}                                                                                       \
\
static void _setter_for_##typeName##_(CBModel* self, SEL _cmd, _TYPE_ value) {          \
    CB_SETTER_PREAMBLE(self, _cmd, info, slot)                                           \
    [self willChangeValueForKey:info.propName];                                         \
    memcpy(slot->_raw.bytes, &value, sizeof(_TYPE_));                                   \
    [self didChangeValueForKey:info.propName];                                          \
}


static id _getter_for_obj_strong_(CBModel* self, SEL _cmd) {
    CB_GETTER_PREAMBLE(self, _cmd, info, slot, nil)
    return slot->_strongValue;
}

static void _setter_for_obj_strong_(CBModel* self, SEL _cmd, id value) {
    CB_SETTER_PREAMBLE(self, _cmd, info, slot)
    [self willChangeValueForKey:info.propName];
    slot->_strongValue = value;
    [self didChangeValueForKey:info.propName];
}

static void _setter_for_obj_copy_(CBModel* self, SEL _cmd, id value) {
    CB_SETTER_PREAMBLE(self, _cmd, info, slot)
    [self willChangeValueForKey:info.propName];
    slot->_strongValue = [value copy];
    [self didChangeValueForKey:info.propName];
}

static id _getter_for_obj_weak_(CBModel* self, SEL _cmd) {
    CB_GETTER_PREAMBLE(self, _cmd, info, slot, nil)
    return slot->_weakValue;
}

static void _setter_for_obj_weak_(CBModel* self, SEL _cmd, id value) {
    CB_SETTER_PREAMBLE(self, _cmd, info, slot)
    [self willChangeValueForKey:info.propName];
    slot->_weakValue = value;
    [self didChangeValueForKey:info.propName];
}

static void* _getter_for_pointer_(CBModel* self, SEL _cmd) {
    CB_GETTER_PREAMBLE(self, _cmd, info, slot, NULL)
    void* value;
    memcpy(&value, slot->_raw.bytes, sizeof(void*));
    return value;
}

static void _setter_for_pointer_(CBModel* self, SEL _cmd, const void* value) {
    CB_SETTER_PREAMBLE(self, _cmd, info, slot)
    [self willChangeValueForKey:info.propName];
    memcpy(slot->_raw.bytes, &value, sizeof(void*));
    [self didChangeValueForKey:info.propName];
}

static void* _getter_for_sel_(CBModel* self, SEL _cmd) {
    CB_GETTER_PREAMBLE(self, _cmd, info, slot, NULL)
    void* value;
    memcpy(&value, slot->_raw.bytes, sizeof(void*));
    return value;
}

static void _setter_for_sel_(CBModel* self, SEL _cmd, __unsafe_unretained id value) {
    CB_SETTER_PREAMBLE(self, _cmd, info, slot)
    [self willChangeValueForKey:info.propName];
    memcpy(slot->_raw.bytes, &value, sizeof(void*));
    [self didChangeValueForKey:info.propName];
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
    CB_GETTER_PREAMBLE(self, _cmd, info, slot, (_TYPE_)0)                                \
    os_unfair_lock_lock(&slot->_lock);                                                  \
    _TYPE_ value;                                                                       \
    memcpy(&value, slot->_raw.bytes, sizeof(_TYPE_));                                   \
    os_unfair_lock_unlock(&slot->_lock);                                                \
    return value;                                                                       \
}                                                                                       \
\
static void _setter_for_atomic_##typeName##_(CBModel* self, SEL _cmd, _TYPE_ value) {   \
    CB_SETTER_PREAMBLE(self, _cmd, info, slot)                                           \
    [self willChangeValueForKey:info.propName];                                         \
    os_unfair_lock_lock(&slot->_lock);                                                  \
    memcpy(slot->_raw.bytes, &value, sizeof(_TYPE_));                                   \
    os_unfair_lock_unlock(&slot->_lock);                                                \
    [self didChangeValueForKey:info.propName];                                          \
}

static id _getter_for_atomic_obj_strong_(CBModel* self, SEL _cmd) {
    CB_GETTER_PREAMBLE(self, _cmd, info, slot, nil)
    os_unfair_lock_lock(&slot->_lock);
    id value = slot->_strongValue;
    os_unfair_lock_unlock(&slot->_lock);
    return value;
}

static void _setter_for_atomic_obj_strong_(CBModel* self, SEL _cmd, id value) {
    CB_SETTER_PREAMBLE(self, _cmd, info, slot)
    [self willChangeValueForKey:info.propName];
    os_unfair_lock_lock(&slot->_lock);
    slot->_strongValue = value;
    os_unfair_lock_unlock(&slot->_lock);
    [self didChangeValueForKey:info.propName];
}

static void _setter_for_atomic_obj_copy_(CBModel* self, SEL _cmd, id value) {
    CB_SETTER_PREAMBLE(self, _cmd, info, slot)
    [self willChangeValueForKey:info.propName];
    os_unfair_lock_lock(&slot->_lock);
    slot->_strongValue = [value copy];
    os_unfair_lock_unlock(&slot->_lock);
    [self didChangeValueForKey:info.propName];
}

static id _getter_for_atomic_obj_weak_(CBModel* self, SEL _cmd) {
    CB_GETTER_PREAMBLE(self, _cmd, info, slot, nil)
    os_unfair_lock_lock(&slot->_lock);
    id value = slot->_weakValue;
    os_unfair_lock_unlock(&slot->_lock);
    return value;
}

static void _setter_for_atomic_obj_weak_(CBModel* self, SEL _cmd, id value) {
    CB_SETTER_PREAMBLE(self, _cmd, info, slot)
    [self willChangeValueForKey:info.propName];
    os_unfair_lock_lock(&slot->_lock);
    slot->_weakValue = value;
    os_unfair_lock_unlock(&slot->_lock);
    [self didChangeValueForKey:info.propName];
}

static void* _getter_for_atomic_pointer_(CBModel* self, SEL _cmd) {
    CB_GETTER_PREAMBLE(self, _cmd, info, slot, NULL)
    os_unfair_lock_lock(&slot->_lock);
    void* value;
    memcpy(&value, slot->_raw.bytes, sizeof(void*));
    os_unfair_lock_unlock(&slot->_lock);
    return value;
}

static void _setter_for_atomic_pointer_(CBModel* self, SEL _cmd, const void* value) {
    CB_SETTER_PREAMBLE(self, _cmd, info, slot)
    [self willChangeValueForKey:info.propName];
    os_unfair_lock_lock(&slot->_lock);
    memcpy(slot->_raw.bytes, &value, sizeof(void*));
    os_unfair_lock_unlock(&slot->_lock);
    [self didChangeValueForKey:info.propName];
}

static void* _getter_for_atomic_sel_(CBModel* self, SEL _cmd) {
    CB_GETTER_PREAMBLE(self, _cmd, info, slot, NULL)
    os_unfair_lock_lock(&slot->_lock);
    void* value;
    memcpy(&value, slot->_raw.bytes, sizeof(void*));
    os_unfair_lock_unlock(&slot->_lock);
    return value;
}

static void _setter_for_atomic_sel_(CBModel* self, SEL _cmd, __unsafe_unretained id value) {
    CB_SETTER_PREAMBLE(self, _cmd, info, slot)
    [self willChangeValueForKey:info.propName];
    os_unfair_lock_lock(&slot->_lock);
    memcpy(slot->_raw.bytes, &value, sizeof(void*));
    os_unfair_lock_unlock(&slot->_lock);
    [self didChangeValueForKey:info.propName];
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

#pragma mark - 类属性（P2：ObjC class property）
// 前置声明（定义在文件后部：selector 映射区 / 属性存储区，宏在文件前部展开需要）
static inline CBMPropInfo CBMPropInfoForSel(Class cls, SEL sel);
static inline NSString *CBMClassPropNameForSel(Class cls, SEL sel);
static void CBMSetupSlotSemantics(CBMPropertySlot *slot, objc_property_t prop);
static CBMPropertySlot *CBMClassPropSlot(Class cls, NSString *propName);

/// 类属性 getter/setter：self 是类对象（Class），值存储 per-class（静态字典 + 锁，低频路径）。
/// 标量/指针/SEL 走 NSValue 装箱（类属性不是热路径，不做裸字节优化）。
#define CLASS_PROP_IMP(typeName, _TYPE_)                                                  \
static _TYPE_ _class_getter_for_##typeName##_(Class self, SEL _cmd) {                     \
    NSString *p = CBMClassPropNameForSel(self, _cmd);                                     \
    if (p == nil) { return (_TYPE_)0; }                                                   \
    CBMPropertySlot *slot = CBMClassPropSlot(self, p);                                    \
    _TYPE_ v;                                                                             \
    memset(&v, 0, sizeof(_TYPE_));   /* 未设置过时 _boxedValue 为 nil，getValue 无操作，保持零值 */ \
    if (@available(iOS 11.0, *)) {                                                        \
        [slot->_boxedValue getValue:&v size:sizeof(_TYPE_)];                              \
    } else {                                                                              \
        [slot->_boxedValue getValue:&v];                                                  \
    }                                                                                     \
    return v;                                                                             \
}                                                                                         \
static void _class_setter_for_##typeName##_(Class self, SEL _cmd, _TYPE_ value) {         \
    NSString *p = CBMClassPropNameForSel(self, _cmd);                                     \
    if (p == nil) { return; }                                                             \
    CBMPropertySlot *slot = CBMClassPropSlot(self, p);                                    \
    slot->_boxedValue = [NSValue value:&value withObjCType:@encode(_TYPE_)];              \
}

static id _class_getter_for_obj_strong_(Class self, SEL _cmd) {
    NSString *p = CBMClassPropNameForSel(self, _cmd);
    if (p == nil) { return nil; }
    return CBMClassPropSlot(self, p)->_strongValue;
}

static void _class_setter_for_obj_strong_(Class self, SEL _cmd, id value) {
    NSString *p = CBMClassPropNameForSel(self, _cmd);
    if (p == nil) { return; }
    CBMClassPropSlot(self, p)->_strongValue = value;
}

static void _class_setter_for_obj_copy_(Class self, SEL _cmd, id value) {
    NSString *p = CBMClassPropNameForSel(self, _cmd);
    if (p == nil) { return; }
    CBMClassPropSlot(self, p)->_strongValue = [value copy];
}

static id _class_getter_for_obj_weak_(Class self, SEL _cmd) {
    NSString *p = CBMClassPropNameForSel(self, _cmd);
    if (p == nil) { return nil; }
    return CBMClassPropSlot(self, p)->_weakValue;
}

static void _class_setter_for_obj_weak_(Class self, SEL _cmd, id value) {
    NSString *p = CBMClassPropNameForSel(self, _cmd);
    if (p == nil) { return; }
    CBMClassPropSlot(self, p)->_weakValue = value;
}

CLASS_PROP_IMP(char, char);
CLASS_PROP_IMP(short, short);
CLASS_PROP_IMP(int, int);
CLASS_PROP_IMP(long, long);
CLASS_PROP_IMP(longLong, long long);
CLASS_PROP_IMP(unsignedChar, unsigned char);
CLASS_PROP_IMP(unsignedInt, unsigned int);
CLASS_PROP_IMP(unsignedShort, unsigned short);
CLASS_PROP_IMP(unsignedLong, unsigned long);
CLASS_PROP_IMP(unsignedLongLong, unsigned long long);
CLASS_PROP_IMP(float, float);
CLASS_PROP_IMP(double, double);
CLASS_PROP_IMP(longDouble, long double);
CLASS_PROP_IMP(bool, bool);

static void* _class_getter_for_pointer_(Class self, SEL _cmd) {
    NSString *p = CBMClassPropNameForSel(self, _cmd);
    if (p == nil) { return NULL; }
    CBMPropertySlot *slot = CBMClassPropSlot(self, p);
    return [slot->_boxedValue pointerValue];
}

static void _class_setter_for_pointer_(Class self, SEL _cmd, const void *value) {
    NSString *p = CBMClassPropNameForSel(self, _cmd);
    if (p == nil) { return; }
    CBMClassPropSlot(self, p)->_boxedValue = [NSValue valueWithPointer:value];
}

static void* _class_getter_for_sel_(Class self, SEL _cmd) {
    NSString *p = CBMClassPropNameForSel(self, _cmd);
    if (p == nil) { return NULL; }
    CBMPropertySlot *slot = CBMClassPropSlot(self, p);
    return (__bridge void *)[slot->_boxedValue nonretainedObjectValue];
}

static void _class_setter_for_sel_(Class self, SEL _cmd, __unsafe_unretained id value) {
    NSString *p = CBMClassPropNameForSel(self, _cmd);
    if (p == nil) { return; }
    CBMClassPropSlot(self, p)->_boxedValue = [NSValue valueWithNonretainedObject:value];
}

/// 类属性的 IMP 选择：支持对象/标量/指针/SEL；结构体/联合体/C 数组返回 nil（类属性暂不支持转发）
static IMP imp_for_class_property(BOOL isSetter, const char *propAttributes) {
    char *typeEncoding = strchr(propAttributes, 'T');
    switch (*(typeEncoding + 1)) {
        case '@': {
            char *attr;
            if ((attr = strstr(strchr(typeEncoding, ','), ",C"))) {
                return isSetter ? (IMP)_class_setter_for_obj_copy_ : (IMP)_class_getter_for_obj_strong_;
            } else if ((attr = strstr(strchr(typeEncoding, ','), ",W"))) {
                return isSetter ? (IMP)_class_setter_for_obj_weak_ : (IMP)_class_getter_for_obj_weak_;
            } else {
                return isSetter ? (IMP)_class_setter_for_obj_strong_ : (IMP)_class_getter_for_obj_strong_;
            }
        }
        case 'c': return isSetter ? (IMP)_class_setter_for_char_ : (IMP)_class_getter_for_char_;
        case 'i': return isSetter ? (IMP)_class_setter_for_int_ : (IMP)_class_getter_for_int_;
        case 's': return isSetter ? (IMP)_class_setter_for_short_ : (IMP)_class_getter_for_short_;
        case 'l': return isSetter ? (IMP)_class_setter_for_long_ : (IMP)_class_getter_for_long_;
        case 'q': return isSetter ? (IMP)_class_setter_for_longLong_ : (IMP)_class_getter_for_longLong_;
        case 'C': return isSetter ? (IMP)_class_setter_for_unsignedChar_ : (IMP)_class_getter_for_unsignedChar_;
        case 'I': return isSetter ? (IMP)_class_setter_for_unsignedInt_ : (IMP)_class_getter_for_unsignedInt_;
        case 'S': return isSetter ? (IMP)_class_setter_for_unsignedShort_ : (IMP)_class_getter_for_unsignedShort_;
        case 'L': return isSetter ? (IMP)_class_setter_for_unsignedLong_ : (IMP)_class_getter_for_unsignedLong_;
        case 'Q': return isSetter ? (IMP)_class_setter_for_unsignedLongLong_ : (IMP)_class_getter_for_unsignedLongLong_;
        case 'f': return isSetter ? (IMP)_class_setter_for_float_ : (IMP)_class_getter_for_float_;
        case 'd': return isSetter ? (IMP)_class_setter_for_double_ : (IMP)_class_getter_for_double_;
        case 'D': return isSetter ? (IMP)_class_setter_for_longDouble_ : (IMP)_class_getter_for_longDouble_;
        case 'B': return isSetter ? (IMP)_class_setter_for_bool_ : (IMP)_class_getter_for_bool_;
        case '^': return isSetter ? (IMP)_class_setter_for_pointer_ : (IMP)_class_getter_for_pointer_;
        case ':': return isSetter ? (IMP)_class_setter_for_sel_ : (IMP)_class_getter_for_sel_;
        default:  return nil;
    }
}

/// 类属性查询：沿 metaclass 链查快查表（类属性表注册在 metaclass 上）。
/// 直接复用 CBMPropInfoForSel（含 nil 保护的 superclass 链遍历，metaclass 链安全）
static inline NSString *CBMClassPropNameForSel(Class cls, SEL sel) {
    return CBMPropInfoForSel(object_getClass(cls), sel).propName;
}

/// 类属性槽：per-class 存储（静态字典 + 锁，低频路径），首次访问时懒创建。
/// 每个（类, 属性名）一个槽——子类经继承调用时创建自己的槽（与 ObjC 类属性 per-class 存储语义一致）
static CBMPropertySlot *CBMClassPropSlot(Class cls, NSString *propName) {
    static os_unfair_lock s_lock = OS_UNFAIR_LOCK_INIT;
    static NSMutableDictionary<NSString*, CBMPropertySlot*> *s_slots;
    os_unfair_lock_lock(&s_lock);
    if (s_slots == nil) {
        s_slots = [NSMutableDictionary dictionary];
    }
    NSString *key = [NSString stringWithFormat:@"%@.%@", NSStringFromClass(cls), propName];
    CBMPropertySlot *slot = s_slots[key];
    if (slot == nil) {
        slot = [[CBMPropertySlot alloc] init];
        // 语义解析：类属性声明在 metaclass 的属性列表里
        objc_property_t prop = class_getProperty(object_getClass(cls), propName.UTF8String);
        if (prop != NULL) {
            CBMSetupSlotSemantics(slot, prop);
        }
        s_slots[key] = slot;
    }
    os_unfair_lock_unlock(&s_lock);
    return slot;
}

@implementation CBMPropertySlot
@end

@implementation CBModel

#pragma mark - KVC 支持
- (id)valueForUndefinedKey:(NSString *)key {
    if (__builtin_expect(!atomic_load_explicit(&_slotsReady, memory_order_acquire), 0)) {
        [self ensureSlotArray];
    }
    NSInteger index = CBMIndexForPropName(object_getClass(self), key);
    if (index < 0) {
        return nil;   // 未解析的属性 → nil（读路径不创建任何存储）
    }
    id value = [self slotValue:_slotArray[index] propName:key];
    
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
                         * 这里直接把value传递出去，由调用端保证类型匹配。
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
                        /* 对于指针、数组、结构体、联合体等复杂类型，无法直接用 NSNumber 装箱，
                         * 这里直接把入参 id 值当对象指针传进去，由调用端保证类型匹配。
                         * 若实际类型不符，运行期会崩溃，属于调用者责任。 */
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
        // long double 与 KVC 里对 'D' 的特殊处理保持一致（无法装箱 NSNumber，用 NSValue 承载）
        case 'D': { long double v; [value getValue:&v]; return [NSString stringWithFormat:@"%Lf", v]; }
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
        if (__builtin_expect(!atomic_load_explicit(&_slotsReady, memory_order_acquire), 0)) {
            [self ensureSlotArray];
        }
        NSInteger index = CBMIndexForPropName(object_getClass(self), key);
        id storedValue = index >= 0 ? [self slotValue:_slotArray[index] propName:key] : nil;
        
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
/// 快查表（v1.4 Phase 1 组件 A）：
/// 热路径用 per-class 固定哈希表（键 = SEL 指针）替代"NSStringFromSelector + 静态锁 + 字符串字典"，
/// 每次属性访问的翻译段从 ~35-85ns 降到 ~10-20ns。
/// 并发模型：解析期在 _sel2PropsLock 临界区内写入 → release 发布表项 → 热路径无锁原子读（acquire）。
/// 表项只写不删、容量固定 → 线性探测链永不被截断、结构永不改变，无锁读安全。
#define CBModel_MAX_SEL_MAPS 32

typedef struct {
    _Atomic(SEL) sel;                    // 空槽 = NULL；解析后 = 该 selector（原子发布/读取）
    __unsafe_unretained NSString *propName;  // 由表 CFRetain 永久持有（一次解析终生有效）
    NSInteger index;                     // 槽数组下标（Phase 2：类链前缀偏移 + 类内序号）
} CBMSelMapEntry;

typedef struct CBMSelMap {
    Class owner;                         // 属性声明类
    CBMSelMapEntry *entries;             // 容量 = 2 的幂，随 map 一并 calloc
    NSUInteger mask;                     // capacity - 1
    NSUInteger baseIndex;                // 类链前缀偏移 = 父链各声明类 @dynamic 属性数之和
} CBMSelMap;

/// 统计 cls 声明的 @dynamic 属性个数（类链容量/偏移计算共用）
static NSUInteger CBMDynamicPropCount(Class cls) {
    NSUInteger count = 0;
    uint listCount;
    objc_property_t *list = class_copyPropertyList(cls, &listCount);
    for (uint i = 0; i < listCount; i++) {
        char *attr = property_copyAttributeValue(list[i], "D");
        if (attr != NULL) {
            count++;
            free(attr);
        }
    }
    free(list);
    return count;
}

#pragma mark - 相等性支持（P2：isEqual: / hash）

/// 实例类链全部 @dynamic 属性名（父→子、类内列表序；与 ensureSlotArray 的槽填充顺序一致）。
/// per-class 关联对象缓存（KVO 子类 miss 时沿链收集，结果与原类一致）。
static NSArray<NSString*> *CBMAllDynamicPropNames(Class cls) {
    static const void *kPropNamesKey = &kPropNamesKey;
    NSArray *cached = objc_getAssociatedObject(cls, kPropNamesKey);
    if (cached) {
        return cached;
    }
    
    Class chain[CBModel_MAX_SEL_MAPS];
    NSUInteger chainCount = 0;
    Class c = cls;
    while (c != NULL && c != CBModel.class) {
        NSCAssert(chainCount < CBModel_MAX_SEL_MAPS, @"CBModel: 类链深度超过上限");
        chain[chainCount++] = c;
        c = class_getSuperclass(c);
    }
    
    NSMutableArray *names = [NSMutableArray array];
    for (NSInteger i = (NSInteger)chainCount - 1; i >= 0; i--) {
        uint listCount;
        objc_property_t *list = class_copyPropertyList(chain[i], &listCount);
        for (uint j = 0; j < listCount; j++) {
            char *attr = property_copyAttributeValue(list[j], "D");
            if (attr != NULL) {
                free(attr);
                [names addObject:[NSString stringWithUTF8String:property_getName(list[j])]];
            }
        }
        free(list);
    }
    objc_setAssociatedObject(cls, kPropNamesKey, names, OBJC_ASSOCIATION_RETAIN);
    return names;
}

/// 裸字节的类型化比较（与 NSNumber 语义一致：-0.0==+0.0、NaN!=NaN）。
/// bytes 来自槽内 _raw union（8 字节对齐），按类型强转读取安全。
static BOOL CBMCompareRawBytes(const unsigned char *a, const unsigned char *b, char typeCode) {
    switch (typeCode) {
        case 'c': return *(char *)a == *(char *)b;
        case 'i': return *(int *)a == *(int *)b;
        case 's': return *(short *)a == *(short *)b;
        case 'l': return *(long *)a == *(long *)b;
        case 'q': return *(long long *)a == *(long long *)b;
        case 'C': return *(unsigned char *)a == *(unsigned char *)b;
        case 'I': return *(unsigned int *)a == *(unsigned int *)b;
        case 'S': return *(unsigned short *)a == *(unsigned short *)b;
        case 'L': return *(unsigned long *)a == *(unsigned long *)b;
        case 'Q': return *(unsigned long long *)a == *(unsigned long long *)b;
        case 'f': return *(float *)a == *(float *)b;
        case 'd': return *(double *)a == *(double *)b;
        case 'D': return *(long double *)a == *(long double *)b;
        case 'B': return *(BOOL *)a == *(BOOL *)b;
        case '^': return *(void **)a == *(void **)b;
        case ':': return *(SEL *)a == *(SEL *)b;
        default:  return memcmp(a, b, 16) == 0;
    }
}

/// 裸字节 hash：浮点零归一（+0.0/-0.0 isEqual 相等，hash 必须一致），
/// 其余按位模式（同值 ⇒ 同位模式 ⇒ 同 hash，与 CBMCompareRawBytes 一致）。
static NSUInteger CBMHashRawBytes(const unsigned char *bytes, char typeCode) {
    NSUInteger v = 0;
    switch (typeCode) {
        case 'f': { float f; memcpy(&f, bytes, sizeof(float)); v = (f == 0) ? 0 : (NSUInteger)(*(unsigned int *)&f); break; }
        case 'd': { double d; memcpy(&d, bytes, sizeof(double)); v = (d == 0) ? 0 : (NSUInteger)(*(unsigned long long *)&d); break; }
        case 'D': { long double ld; memcpy(&ld, bytes, sizeof(long double)); v = (ld == 0) ? 0 : (NSUInteger)(*(unsigned long long *)&ld); break; }
        default:  memcpy(&v, bytes, sizeof(NSUInteger)); break;
    }
    return (NSUInteger)(v * 2654435761u);
}

/// 类链前缀偏移：cls 父链（到 CBModel 止）各声明类 @dynamic 属性数之和，
/// 与 ensureSlotArray 的实例容量枚举同一逻辑，保证 index < 容量恒成立
static NSUInteger CBMSelMapBaseIndex(Class cls) {
    NSUInteger base = 0;
    Class c = class_getSuperclass(cls);
    while (c != NULL && c != CBModel.class) {
        base += CBMDynamicPropCount(c);
        c = class_getSuperclass(c);
    }
    return base;
}

/// 热路径查询：沿类链查快表，一次拿 {propName, index}（无锁原子读）。
/// 链终止：实例链到 CBModel 止；metaclass 链（类属性查询）到 nil 止——nil 保护防死循环。
static inline CBMPropInfo CBMPropInfoForSel(Class cls, SEL sel) {
    do {
        CBMSelMap *map = CBMSelMapForClass(cls);
        if (map != NULL) {
            NSUInteger slot = CBMSelHash(sel) & map->mask;
            for (;;) {
                SEL s = atomic_load_explicit(&map->entries[slot].sel, memory_order_acquire);
                if (s == NULL) {
                    break;
                }
                if (s == sel) {
                    return (CBMPropInfo){map->entries[slot].propName, map->entries[slot].index};
                }
                slot = (slot + 1) & map->mask;
            }
        }
    } while (cls != nil && (cls = class_getSuperclass(cls)) != CBModel.class);
    return (CBMPropInfo){nil, -1};
}

/// 沿类链遍历各表全表扫描（容量小，低频可接受）；子类优先。
static NSInteger CBMIndexForPropName(Class cls, NSString *propName) {
    do {
        CBMSelMap *map = CBMSelMapForClass(cls);
        if (map != NULL) {
            for (NSUInteger i = 0; i <= map->mask; i++) {
                SEL s = atomic_load_explicit(&map->entries[i].sel, memory_order_acquire);
                if (s != NULL && [map->entries[i].propName isEqualToString:propName]) {
                    return map->entries[i].index;
                }
            }
        }
    } while ((cls = class_getSuperclass(cls)) != CBModel.class);
    return -1;
}

static _Atomic(CBMSelMap *) _selMaps[CBModel_MAX_SEL_MAPS];
static _Atomic(NSUInteger) _selMapCount;

static NSUInteger CBMSelHash(SEL sel) {
    // SEL 是进程内唯一指针且通常 16 字节对齐：先右移去低位零，再乘黄金比例常数打散
    return (NSUInteger)(((uintptr_t)sel >> 4) * 2654435761u);
}

/// 类 → 表 查找（无锁）：_selMapCount 的 release/acquire 保证 [0, count) 内表指针已完整发布
static inline CBMSelMap *CBMSelMapForClass(Class cls) {
    NSUInteger count = atomic_load_explicit(&_selMapCount, memory_order_acquire);
    for (NSUInteger i = 0; i < count; i++) {
        CBMSelMap *map = atomic_load_explicit(&_selMaps[i], memory_order_acquire);
        if (map->owner == cls) {
            return map;
        }
    }
    return NULL;
}

/// 表内查询（无锁）：hash(sel) 起点线性探测，遇空槽终止（表项只写不删，探测链完整）
/// 已内联进 CBMPropInfoForSel（一次查表同时返回 propName 与 index），此处不再单独提供

/// 确保 cls 的表存在并写入 {sel, propName, index}（必须在持有 _sel2PropsLock 时调用，内部不重复加锁）。
/// 容量 = cls 声明的 @dynamic 属性数 × 4（每属性 getter+setter 两键 × 2 安全系数，负载 ≤ 0.5），
/// 上取 2 的幂；分配后容量固定，表项只写不删 → 热路径无锁读安全。
/// propIndex = 属性在 cls 属性列表中的位置（resolveInstanceMethod/forwardInvocation 扫描时即得），
/// 槽下标 = baseIndex(类链前缀偏移) + propIndex。
static void CBMSelMapEnsureAndWrite(Class cls, SEL sel, NSString *propName, NSInteger propIndex) {
    CBMSelMap *map = CBMSelMapForClass(cls);
    if (map == NULL) {
        NSUInteger propCount = CBMDynamicPropCount(cls);
        NSUInteger capacity = 4;
        while (capacity < propCount * 4) {
            capacity <<= 1;
        }
        
        map = calloc(1, sizeof(CBMSelMap) + capacity * sizeof(CBMSelMapEntry));
        map->owner = cls;
        map->entries = (CBMSelMapEntry *)(map + 1);
        map->mask = capacity - 1;
        map->baseIndex = CBMSelMapBaseIndex(cls);
        
        NSUInteger idx = atomic_load_explicit(&_selMapCount, memory_order_relaxed);
        NSCAssert(idx < CBModel_MAX_SEL_MAPS, @"CBModel: 模型类数量超过上限 %d", CBModel_MAX_SEL_MAPS);
        atomic_store_explicit(&_selMaps[idx], map, memory_order_release);
        atomic_store_explicit(&_selMapCount, idx + 1, memory_order_release);
    }
    
    // 探测写入：先写 propName/index（锁内普通写），最后 release 发布 sel → 读者 acquire 命中即见完整表项。
    // propName 由表 CFRetain 永久持有（永不释放，符合"一次解析终生有效"；C 结构不能持有 strong 对象）
    NSUInteger slot = CBMSelHash(sel) & map->mask;
    while (atomic_load_explicit(&map->entries[slot].sel, memory_order_relaxed) != NULL) {
        slot = (slot + 1) & map->mask;
    }
    CFRetain((__bridge CFTypeRef)propName);
    map->entries[slot].propName = propName;
    map->entries[slot].index = (NSInteger)map->baseIndex + propIndex;
    atomic_store_explicit(&map->entries[slot].sel, sel, memory_order_release);
}

/// 类级缓存静态锁：resolveInstanceMethod: 可能被多线程并发触发（不同 selector 首次访问），
/// 快查表的建表/写表/发布 IMP 都必须在该锁内原子完成（映射先于 IMP 发布的不变量）。
/// 静态存储的 os_unfair_lock 用 OS_UNFAIR_LOCK_INIT 显式初始化，无需运行时初始化。
static os_unfair_lock _sel2PropsLock = OS_UNFAIR_LOCK_INIT;

/// 动态方法安装：在类级缓存锁内完成"查重 → 写映射 → class_addMethod"。
/// 必须保证映射先于 IMP 发布且两者原子一致——否则并发首次解析时会出现
/// "IMP 已发布但映射未写入"的窗口：其他线程立即调用 setter 会拿到 nil 属性名而崩溃
/// （映射与 IMP 的可见性由 _sel2PropsLock 的 happens-before 保证）。
/// 返回是否成功添加（已存在映射则返回 NO，由调用方交给 runtime 重试查找）。
/// 以 C 函数形式提供，实例属性与类属性两条路径共用：
/// 实测在 resolveClassMethod 内以消息发送方式调用同类类方法（+installDynamicMethod:）
/// 会命中转发路径（方法缓存问题）导致 unrecognized selector，故统一直接函数调用。
static BOOL CBMInstallDynamicMethod(Class cls, SEL sel, IMP imp, const char *types,
                                    NSString *propName, NSInteger propIndex) {
    os_unfair_lock_lock(&_sel2PropsLock);
    BOOL added = NO;
    if (CBMPropInfoForSel(cls, sel).index < 0) {
        CBMSelMapEnsureAndWrite(cls, sel, propName, propIndex);   // 快查表（热路径用）
        added = class_addMethod(cls, sel, imp, types);
        // 竞争失败（其他线程已添加同名方法）时无需回滚：映射内容一致，重复写入无害
    }
    os_unfair_lock_unlock(&_sel2PropsLock);
    return added;
}

+ (BOOL)installDynamicMethod:(SEL)sel
                        imp:(IMP)imp
                      types:(const char*)types
                   propName:(NSString*)propName
                  propIndex:(NSInteger)propIndex {
    return CBMInstallDynamicMethod(self, sel, imp, types, propName, propIndex);
}

#pragma mark - 属性存储（槽数组，v1.4 Phase 2 组件 B）
/// 按属性编码设置槽的存储语义与原子性（ensureSlotArray 与类属性槽共用）
static void CBMSetupSlotSemantics(CBMPropertySlot *slot, objc_property_t prop) {
    char *typeAttr = property_copyAttributeValue(prop, "T");
    char *nonatomicAttr = property_copyAttributeValue(prop, "N");
    slot->atomic = (nonatomicAttr == NULL);
    free(nonatomicAttr);
    if (typeAttr != NULL && typeAttr[0] == '@') {
        char *weakAttr = property_copyAttributeValue(prop, "W");
        slot->storage = weakAttr ? CBMPropStorageWeak : CBMPropStorageStrong;
        free(weakAttr);
    } else if (typeAttr != NULL &&
               (typeAttr[0] == '{' || typeAttr[0] == '(' || typeAttr[0] == '[')) {
        // 结构体/联合体/C 数组：大小不定，保留 NSValue 装箱
        slot->storage = CBMPropStorageBoxed;
    } else {
        // 标量/指针/SEL：裸字节存储（v1.4 2.5，long double 最大 16B 在容量内）
        slot->storage = CBMPropStorageRaw;
    }
    free(typeAttr);
}

/// 槽数组初始化：容量 = 实例类链各声明类 @dynamic 属性总数（与快查表 baseIndex 同一枚举逻辑），
/// 为每个属性预创建槽对象并按属性编码设置存储语义。
/// 锁内双检 + _slotsReady 原子发布：写 _slotArray → release store → 热路径 acquire load 后无锁读。
- (void)ensureSlotArray {
    os_unfair_lock_lock(&_initLock);
    if (!atomic_load_explicit(&_slotsReady, memory_order_acquire)) {
        // 收集类链（子→父），上限与 _selMaps 一致
        Class chain[CBModel_MAX_SEL_MAPS];
        NSUInteger chainCount = 0;
        Class cls = object_getClass(self);
        while (cls != NULL && cls != CBModel.class) {
            NSCAssert(chainCount < CBModel_MAX_SEL_MAPS, @"CBModel: 类链深度超过上限");
            chain[chainCount++] = cls;
            cls = class_getSuperclass(cls);
        }
        
        NSUInteger capacity = 0;
        for (NSUInteger i = 0; i < chainCount; i++) {
            capacity += CBMDynamicPropCount(chain[i]);
        }
        
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:capacity];
        // 逆序填充（父→子）：槽数组下标 = baseIndex(类链前缀偏移) + 类内序号（与快查表 index 一致）
        for (NSInteger i = (NSInteger)chainCount - 1; i >= 0; i--) {
            uint listCount;
            objc_property_t *list = class_copyPropertyList(chain[i], &listCount);
            for (uint j = 0; j < listCount; j++) {
                char *attr = property_copyAttributeValue(list[j], "D");
                if (attr == NULL) {
                    continue;
                }
                free(attr);
                
                CBMPropertySlot *slot = [[CBMPropertySlot alloc] init];
                CBMSetupSlotSemantics(slot, list[j]);
                [array addObject:slot];
            }
            free(list);
        }
        
        _slotArray = array;
        atomic_store_explicit(&_slotsReady, YES, memory_order_release);
    }
    os_unfair_lock_unlock(&_initLock);
}

/// 冷路径取"可装箱值"（KVC/description/sDynamicProperties 合成用）：
/// Raw 槽按属性 T 编码临时装箱（低频路径，装箱开销无所谓）
- (id)slotValue:(CBMPropertySlot *)slot propName:(NSString *)propName {
    switch (slot->storage) {
        case CBMPropStorageStrong: return slot->_strongValue;
        case CBMPropStorageWeak:   return slot->_weakValue;
        case CBMPropStorageBoxed:  return slot->_boxedValue;
        case CBMPropStorageRaw: {
            objc_property_t prop = class_getProperty([self class], propName.UTF8String);
            char *typeAttr = prop ? property_copyAttributeValue(prop, "T") : NULL;
            NSValue *v = typeAttr ? [NSValue valueWithBytes:slot->_raw.bytes objCType:typeAttr] : nil;
            free(typeAttr);
            return v;
        }
    }
    return nil;
}

#pragma mark - 相等性（P2：Model 去重/缓存/NSSet 场景）
/// 值语义比较：属性名集合一致 + 逐属性类型化比较。
/// 未触碰的属性按默认零值参与比较（与"显式设置为 0/nil"等价）。
- (BOOL)isEqualToModel:(CBModel *)other {
    if (self == other) {
        return YES;
    }
    if (![other isKindOfClass:[CBModel class]]) {
        return NO;
    }
    // 属性名集合一致（KVO swizzle 后 isa 链与原类属性集一致，天然兼容）
    NSArray<NSString*> *myNames = CBMAllDynamicPropNames(object_getClass(self));
    NSArray<NSString*> *otherNames = CBMAllDynamicPropNames(object_getClass(other));
    if (![myNames isEqualToArray:otherNames]) {
        return NO;
    }
    for (NSString *propName in myNames) {
        if (![self cb_isValueEqual:other forPropName:propName]) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[CBModel class]]) {
        return [self isEqualToModel:(CBModel *)object];
    }
    return [super isEqual:object];
}

/// hash 覆盖全部 @dynamic 属性（与 isEqual 一致：等值 ⇒ 逐属性 hash 相同 ⇒ 组合相同）
- (NSUInteger)hash {
    NSUInteger h = 0;
    NSArray<NSString*> *names = CBMAllDynamicPropNames(object_getClass(self));
    for (NSString *propName in names) {
        h = h * 31 + [self cb_propHash:propName];
    }
    return h;
}

/// 单属性比较（两边取值；未触碰的一边按默认零值参与）
- (BOOL)cb_isValueEqual:(CBModel *)other forPropName:(NSString *)propName {
    NSInteger i1 = CBMIndexForPropName(object_getClass(self), propName);
    NSInteger i2 = CBMIndexForPropName(object_getClass(other), propName);
    // 注册表是 per-class 的（其他实例触碰过即注册），本实例槽数组可能未初始化——取槽前确保就绪
    if (i1 >= 0 && __builtin_expect(!atomic_load_explicit(&_slotsReady, memory_order_acquire), 0)) {
        [self ensureSlotArray];
    }
    if (i2 >= 0 && __builtin_expect(!atomic_load_explicit(&other->_slotsReady, memory_order_acquire), 0)) {
        [other ensureSlotArray];
    }
    CBMPropertySlot *s1 = i1 >= 0 ? _slotArray[i1] : nil;
    CBMPropertySlot *s2 = i2 >= 0 ? other->_slotArray[i2] : nil;
    if (s1 == nil && s2 == nil) {
        return YES;
    }
    
    objc_property_t prop = class_getProperty(object_getClass(self), propName.UTF8String);
    char *typeAttr = prop ? property_copyAttributeValue(prop, "T") : NULL;
    char typeCode = typeAttr ? typeAttr[0] : 0;
    free(typeAttr);
    
    if (typeCode == '@') {
        id v1 = s1 ? (s1->storage == CBMPropStorageWeak ? s1->_weakValue : s1->_strongValue) : nil;
        id v2 = s2 ? (s2->storage == CBMPropStorageWeak ? s2->_weakValue : s2->_strongValue) : nil;
        return (v1 == v2) || [v1 isEqual:v2];
    }
    if (typeCode == '{' || typeCode == '(' || typeCode == '[') {
        NSValue *v1 = s1 ? s1->_boxedValue : nil;
        NSValue *v2 = s2 ? s2->_boxedValue : nil;
        return (v1 == v2) || [v1 isEqual:v2];
    }
    // Raw 标量/指针/SEL：未触碰 = 全零字节（零值），类型化比较
    static const unsigned char zero[16] = {0};
    const unsigned char *b1 = s1 ? s1->_raw.bytes : zero;
    const unsigned char *b2 = s2 ? s2->_raw.bytes : zero;
    return CBMCompareRawBytes(b1, b2, typeCode);
}

/// 单属性 hash（未触碰 → 零值 hash，与 isEqual 的默认值语义一致）
- (NSUInteger)cb_propHash:(NSString *)propName {
    NSInteger index = CBMIndexForPropName(object_getClass(self), propName);
    if (index < 0) {
        return 0;
    }
    // 注册表是 per-class 的，本实例槽数组可能未初始化——取槽前确保就绪
    if (__builtin_expect(!atomic_load_explicit(&_slotsReady, memory_order_acquire), 0)) {
        [self ensureSlotArray];
    }
    CBMPropertySlot *slot = _slotArray[index];
    switch (slot->storage) {
        case CBMPropStorageStrong: return [slot->_strongValue hash];   // nil → 0
        case CBMPropStorageWeak:   return [slot->_weakValue hash];
        case CBMPropStorageBoxed:  return [slot->_boxedValue hash];
        case CBMPropStorageRaw: {
            objc_property_t prop = class_getProperty(object_getClass(self), propName.UTF8String);
            char *typeAttr = prop ? property_copyAttributeValue(prop, "T") : NULL;
            NSUInteger h = typeAttr ? CBMHashRawBytes(slot->_raw.bytes, typeAttr[0]) : 0;
            free(typeAttr);
            return h;
        }
    }
    return 0;
}

/// 结构体/联合体属性无预编译 IMP（imp_for_property 返回 nil），首次走转发时在锁内注册表项。
/// 注册到属性声明类（与 resolveInstanceMethod 语义一致），查询从实例 isa 链出发（兼容 KVO 子类）。
- (NSInteger)ensureForwardedPropIndex:(Class)declaringClass
                                  sel:(SEL)sel
                             propName:(NSString *)propName
                            propIndex:(NSInteger)propIndex {
    Class lookupCls = object_getClass(self);
    CBMPropInfo info = CBMPropInfoForSel(lookupCls, sel);
    if (info.index >= 0) {
        return info.index;
    }
    os_unfair_lock_lock(&_sel2PropsLock);
    info = CBMPropInfoForSel(lookupCls, sel);   // 锁内双检
    if (info.index < 0) {
        CBMSelMapEnsureAndWrite(declaringClass, sel, propName, propIndex);
        info = CBMPropInfoForSel(lookupCls, sel);
    }
    os_unfair_lock_unlock(&_sel2PropsLock);
    return info.index;
}

#pragma mark - 属性映射表（按需合成，替代原共享容器）
/// 强引用属性字典（按需合成）：遍历类链快查表，子类同名属性优先。
/// 原实现返回"活容器"，现为合成快照——外部修改不影响内部（readonly 语义更严谨）。
- (NSMutableDictionary<NSString*, id> *)sDynamicProperties {
    if (__builtin_expect(!atomic_load_explicit(&_slotsReady, memory_order_acquire), 0)) {
        [self ensureSlotArray];
    }
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    Class cls = object_getClass(self);
    while (cls != NULL && cls != CBModel.class) {
        CBMSelMap *map = CBMSelMapForClass(cls);
        if (map != NULL) {
            for (NSUInteger i = 0; i <= map->mask; i++) {
                SEL s = atomic_load_explicit(&map->entries[i].sel, memory_order_acquire);
                if (s != NULL) {
                    NSString *propName = map->entries[i].propName;
                    if (dict[propName] == nil) {
                        CBMPropertySlot *slot = _slotArray[map->entries[i].index];
                        id value = [self slotValue:slot propName:propName];
                        if (value != nil) {
                            dict[propName] = value;
                        }
                    }
                }
            }
        }
        cls = class_getSuperclass(cls);
    }
    return dict;
}

/// 弱引用属性表（按需合成）：仅收集 weak 槽，值已置 nil 的条目跳过
- (NSMapTable<NSString*, id> *)wDynamicProperties {
    if (__builtin_expect(!atomic_load_explicit(&_slotsReady, memory_order_acquire), 0)) {
        [self ensureSlotArray];
    }
    NSMapTable *table = [NSMapTable strongToWeakObjectsMapTable];
    Class cls = object_getClass(self);
    while (cls != NULL && cls != CBModel.class) {
        CBMSelMap *map = CBMSelMapForClass(cls);
        if (map != NULL) {
            for (NSUInteger i = 0; i <= map->mask; i++) {
                SEL s = atomic_load_explicit(&map->entries[i].sel, memory_order_acquire);
                if (s != NULL) {
                    CBMPropertySlot *slot = _slotArray[map->entries[i].index];
                    if (slot->storage == CBMPropStorageWeak && slot->_weakValue != nil) {
                        [table setObject:slot->_weakValue
                                  forKey:map->entries[i].propName];
                    }
                }
            }
        }
        cls = class_getSuperclass(cls);
    }
    return table;
}

@synthesize propertyLocks = _propertyLocks;
/// 兼容保留：per-property 锁体系已废弃（存储已改为 per-属性槽），该表不再被内部使用
- (NSMutableDictionary<NSString*, NSLock*> *)propertyLocks {
    if (_propertyLocks == nil) {
        _propertyLocks = [NSMutableDictionary dictionary];
    }
    return _propertyLocks;
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
        // @dynamic 属性序号（跳过自动合成等非动态属性）：与 ensureSlotArray 的槽填充顺序、
        // CBMDynamicPropCount 的计数一致，保证 index 不越界
        NSInteger dynIndex = 0;
        for (int j = 0; j < propCount; j++) {
            curProp = propList[j];
            // 判断是不是动态属性，dynamic 修饰
            char* attrValue = property_copyAttributeValue(curProp, "D");
            free(attrValue); if (attrValue == NULL) { continue; } attrValue = NULL;
            NSInteger propIndex = dynIndex++;
            
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
                    
                    // 动态添加方法实现（映射与 IMP 原子发布，见 installDynamicMethod:）
                    IMP impForProp = imp_for_property(NO, isAtomic, property_getAttributes(curProp));
                    if (getterTypes &&
                        impForProp &&
                        [cls installDynamicMethod:sel
                                             imp:impForProp
                                           types:getterTypes
                                        propName:targetPropName
                                       propIndex:propIndex]) {
                        resolve = YES;
                        break;
                    }
                }
            }
            
            { // setter处理
                // readonly 属性（属性编码含 'R'）只注入 getter、不注入 setter，
                // 调用 setter 走 unrecognized selector（标准 ObjC 语义）
                char *readonlyAttr = property_copyAttributeValue(curProp, "R");
                BOOL isReadonly = (readonlyAttr != NULL);
                free(readonlyAttr);
                if (isReadonly) {
                    continue;
                }
                
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
                    
                    // 动态添加方法实现（映射与 IMP 原子发布，见 installDynamicMethod:）
                    IMP impForProp = imp_for_property(YES, isAtomic, property_getAttributes(curProp));
                    if (setterTypes &&
                        impForProp &&
                        [cls installDynamicMethod:sel
                                             imp:impForProp
                                           types:setterTypes
                                        propName:targetPropName
                                       propIndex:propIndex]) {
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

#pragma mark - 类方法解析（类属性，P2）
/// 类属性解析：类属性的 getter/setter 是类方法（注册在 metaclass 上）。
/// 遍历 metaclass 链的属性列表（类属性存储于 metaclass），与实例属性同一套
/// getter/setter 名匹配；映射原子发布走 CBMInstallDynamicMethod 直接函数调用
/// （resolveClassMethod 内以消息方式调用同类类方法会命中转发路径，见该函数注释）。
+ (BOOL)resolveClassMethod:(SEL)sel {
    if (![self isSubclassOfClass:CBModel.class]) {
        return [super resolveClassMethod:sel];
    }
    
    BOOL resolve = NO;
    NSString *targetSelName = NSStringFromSelector(sel);
    Class cls = object_getClass(self);   // metaclass
    do {
        uint propCount;
        objc_property_t *propList = class_copyPropertyList(cls, &propCount);
        objc_property_t curProp;
        NSInteger dynIndex = 0;
        for (int j = 0; j < propCount; j++) {
            curProp = propList[j];
            // 判断是不是动态属性，dynamic 修饰
            char *attrValue = property_copyAttributeValue(curProp, "D");
            free(attrValue); if (attrValue == NULL) { continue; } attrValue = NULL;
            NSInteger propIndex = dynIndex++;
            
            // 提取属性名
            const char *propName = property_getName(curProp);
            NSString *targetPropName = [NSString stringWithUTF8String:propName];
            
            { // getter处理
                NSString *propGetterName = nil;
                attrValue = property_copyAttributeValue(curProp, "G");
                if (attrValue) {
                    propGetterName = [NSString stringWithFormat:@"%s", attrValue];
                    free(attrValue); attrValue = NULL;
                } else {
                    propGetterName = [NSString stringWithFormat:@"%s", propName];
                }
                if ([targetSelName isEqualToString:propGetterName]) {
                    attrValue = property_copyAttributeValue(curProp, "T");
                    const char *getterTypes = [NSString stringWithFormat:@"%s:", attrValue].UTF8String;
                    free(attrValue); attrValue = NULL;
                    
                    IMP impForProp = imp_for_class_property(NO, property_getAttributes(curProp));
                    if (getterTypes &&
                        impForProp &&
                        CBMInstallDynamicMethod(cls, sel, impForProp, getterTypes, targetPropName, propIndex)) {
                        resolve = YES;
                        break;
                    }
                }
            }
            
            { // setter处理
                // readonly 类属性只注入 getter（与实例 readonly 语义一致）
                char *readonlyAttr = property_copyAttributeValue(curProp, "R");
                BOOL isReadonly = (readonlyAttr != NULL);
                free(readonlyAttr);
                if (isReadonly) {
                    continue;
                }
                
                NSString *propSetterName = nil;
                attrValue = property_copyAttributeValue(curProp, "S");
                if (attrValue) {
                    propSetterName = [NSString stringWithFormat:@"%s", attrValue];
                    free(attrValue); attrValue = NULL;
                } else {
                    propSetterName = [NSString stringWithFormat:@"set%c%s:", propName[0] & ~0x20, propName + 1];
                }
                if ([targetSelName isEqualToString:propSetterName]) {
                    attrValue = property_copyAttributeValue(curProp, "T");
                    const char *setterTypes = [NSString stringWithFormat:@"v:%s:", attrValue].UTF8String;
                    free(attrValue); attrValue = NULL;
                    
                    IMP impForProp = imp_for_class_property(YES, property_getAttributes(curProp));
                    if (setterTypes &&
                        impForProp &&
                        CBMInstallDynamicMethod(cls, sel, impForProp, setterTypes, targetPropName, propIndex)) {
                        resolve = YES;
                        break;
                    }
                }
            }
        }
        // 释放属性列表
        free(propList); propList = NULL;
        if (resolve) { return YES; }
    } while ((cls = [cls superclass]) != object_getClass(CBModel.class));
    
    return [super resolveClassMethod:sel];
}

#pragma mark - 消息转发签名
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSMethodSignature *signature = [super methodSignatureForSelector:aSelector];
    if (signature) {
        return signature;
    }
    
    Class cls = self.class;
    NSString *targetSelName = NSStringFromSelector(aSelector);
    
    do {
        uint propCount;
        objc_property_t *propList = class_copyPropertyList(cls, &propCount);
        
        for (uint j = 0; j < propCount; j++) {
            objc_property_t curProp = propList[j];
            
            char *attrValue = property_copyAttributeValue(curProp, "D");
            if (attrValue == NULL) {
                continue;
            }
            free(attrValue);
            
            const char *propName = property_getName(curProp);
            char *typeAttr = property_copyAttributeValue(curProp, "T");
            
            if (typeAttr == NULL) {
                continue;
            }
            
            NSString *propGetterName = nil;
            NSString *propSetterName = nil;
            
            char *getterAttr = property_copyAttributeValue(curProp, "G");
            if (getterAttr) {
                propGetterName = [NSString stringWithUTF8String:getterAttr];
                free(getterAttr);
            } else {
                propGetterName = [NSString stringWithUTF8String:propName];
            }
            
            char *setterAttr = property_copyAttributeValue(curProp, "S");
            if (setterAttr) {
                propSetterName = [NSString stringWithUTF8String:setterAttr];
                free(setterAttr);
            } else {
                propSetterName = [NSString stringWithFormat:@"set%c%s:", toupper(propName[0]), propName + 1];
            }
            
            NSString *typeStr = [NSString stringWithUTF8String:typeAttr];
            
            if ([targetSelName isEqualToString:propGetterName]) {
                NSString *sigStr = [NSString stringWithFormat:@"%@@:", typeStr];
                signature = [NSMethodSignature signatureWithObjCTypes:sigStr.UTF8String];
                free(typeAttr);
                free(propList);
                return signature;
            }
            
            // readonly 属性（属性编码含 'R'）不提供 setter 签名（只注入 getter 语义）
            char *readonlyAttr = property_copyAttributeValue(curProp, "R");
            BOOL isReadonly = (readonlyAttr != NULL);
            free(readonlyAttr);
            if (isReadonly) {
                free(typeAttr);
                continue;
            }
            
            if ([targetSelName isEqualToString:propSetterName]) {
                NSString *sigStr = [NSString stringWithFormat:@"v@:%@", typeStr];
                signature = [NSMethodSignature signatureWithObjCTypes:sigStr.UTF8String];
                free(typeAttr);
                free(propList);
                return signature;
            }
            
            free(typeAttr);
        }
        
        free(propList);
    } while ((cls = [cls superclass]) != CBModel.class);
    
    return nil;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    BOOL resolve = NO;
    
    Class cls = self.class;
    NSString* targetSelName = NSStringFromSelector(anInvocation.selector);
    
    do {
        uint propCount;
        objc_property_t *propList = class_copyPropertyList(cls, &propCount);
        objc_property_t curProp;
        // @dynamic 属性序号（与 resolveInstanceMethod/ensureSlotArray 保持一致）
        NSInteger dynIndex = 0;
        for (int j = 0; j < propCount; j++) {
            curProp = propList[j];
            // 判断是不是动态属性，dynamic 修饰
            char* attrValue = property_copyAttributeValue(curProp, "D");
            free(attrValue); if (attrValue == NULL) { continue; } attrValue = NULL;
            NSInteger propIndex = dynIndex++;
            
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
                    
                    // 结构体/联合体属性无预编译 IMP，首次转发时在锁内注册表项（幂等）
                    NSInteger index = [self ensureForwardedPropIndex:cls
                                                                 sel:anInvocation.selector
                                                            propName:targetPropName
                                                           propIndex:propIndex];
                    if (index < 0) {
                        break;
                    }
                    if (index < 0) {
                        break;
                    }
                    if (__builtin_expect(!atomic_load_explicit(&_slotsReady, memory_order_acquire), 0)) {
                        [self ensureSlotArray];
                    }
                    CBMPropertySlot* slot = self->_slotArray[index];
                    
                    NSValue* value = nil;
                    if (slot->atomic) {
                        os_unfair_lock_lock(&slot->_lock);
                    }
                    value = slot->_boxedValue;
                    if (value) {
                        void* buff = alloca(retSize);
                        memset(buff, 0, retSize);
                        [value getValue:buff size:retSize];
                        [anInvocation setReturnValue:buff];
                    }
                    if (slot->atomic) {
                        os_unfair_lock_unlock(&slot->_lock);
                    }
                    resolve = YES;
                    break;
                }
            }
            
            { // setter处理
                // readonly 属性（属性编码含 'R'）只注入 getter、不注入 setter（转发路径同样跳过）
                char *readonlyAttr = property_copyAttributeValue(curProp, "R");
                BOOL isReadonly = (readonlyAttr != NULL);
                free(readonlyAttr);
                if (isReadonly) {
                    continue;
                }
                
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
                    
                    // 结构体/联合体属性无预编译 IMP，首次转发时在锁内注册表项（幂等）
                    NSInteger index = [self ensureForwardedPropIndex:cls
                                                                 sel:anInvocation.selector
                                                            propName:targetPropName
                                                           propIndex:propIndex];
                    if (index < 0) {
                        break;
                    }
                    if (__builtin_expect(!atomic_load_explicit(&_slotsReady, memory_order_acquire), 0)) {
                        [self ensureSlotArray];
                    }
                    CBMPropertySlot* slot = self->_slotArray[index];
                    
                    // KVO 规范要求 willChange 必须先于变更（观测者在 willChange 内取旧值快照），
                    // 与标量/对象 setter 的顺序保持一致
                    [self willChangeValueForKey:targetPropName];
                    
                    if (slot->atomic) {
                        os_unfair_lock_lock(&slot->_lock);
                    }
                    slot->_boxedValue = [NSValue value:buff withObjCType:argTypeCode];
                    if (slot->atomic) {
                        os_unfair_lock_unlock(&slot->_lock);
                    }
                    
                    [self didChangeValueForKey:targetPropName];
                    
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
