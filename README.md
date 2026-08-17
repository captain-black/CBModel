# CBModel

[![Version](https://img.shields.io/cocoapods/v/CBModel.svg?style=flat)](https://cocoapods.org/pods/CBModel)
[![License](https://img.shields.io/cocoapods/l/CBModel.svg?style=flat)](https://cocoapods.org/pods/CBModel)
[![Platform](https://img.shields.io/cocoapods/p/CBModel.svg?style=flat)](https://cocoapods.org/pods/CBModel)

面向**服务端驱动数据模型**场景的 Objective-C 动态属性引擎：子类声明 `@dynamic` 属性即自动获得 getter/setter，支持运行时动态添加属性（插件化）。

JSON 序列化/反序列化建议配合 [YYModel](https://github.com/ibireme/YYModel) 使用（CBModel 保持单一职责，只做动态属性引擎）。

## 特性

- **自动属性注入**：子类声明 `@dynamic` 属性，getter/setter 由 CBModel 自动解析注入，无需手写实现
- **全类型覆盖**：14 种标量（char/int/short/long/long long/unsigned 系列/float/double/long double/BOOL）、对象（strong/copy/weak）、指针、SEL、Class、**常见结构体（CGPoint/CGSize/CGRect/NSRange/UIEdgeInsets/CGAffineTransform/CATransform3D）**、任意自定义结构体（转发兜底）
- **atomic 支持**：per-属性槽锁，跨属性并发不串行
- **KVC / KVO**：结构体属性同样支持
- **readonly 属性**：只注入 getter、不注入 setter（标准 ObjC 语义）
- **类属性（Class Property）**：类级状态存储
- **值语义相等性**：`isEqual:` / `hash` 覆盖全部属性，支持 NSSet 去重/缓存场景
- **插件化**：运行中动态注册任意数量的模型类（`objc_allocateClassPair` + `class_addProperty`），类表 COW 自动增长无上限
- **高性能**：快查表（SEL 指针哈希，无锁原子读）+ per-属性裸字节槽存储，热路径 ~45ns/操作（标量）、~60-80ns/操作（结构体），未知结构体走签名缓存转发（免扫描）

## 使用

```objc
#import "CBModel.h"

@interface UserModel : CBModel
@property (nonatomic) NSInteger userId;
@property (nonatomic, strong) NSString *name;
@property (nonatomic) CGPoint position;          // 结构体走预编译 IMP（热路径）
@property (nonatomic) MyCustomStruct extra;      // 自定义结构体走转发兜底
@end

@implementation UserModel
@dynamic userId;
@dynamic name;
@dynamic position;
@dynamic extra;
@end

// 使用
UserModel *user = [[UserModel alloc] init];
user.userId = 42;                        // 自动注入的 setter
user.name = @"Alice";
user.position = CGPointMake(10, 20);

[user setValue:@(7) forKey:@"userId"];   // KVC
NSString *desc = user.description;       // 自动格式化输出全部属性
```

### 运行时动态属性（插件场景）

```objc
Class cls = objc_allocateClassPair(CBModel.class, "DynModel", 0);
objc_property_attribute_t type = {"T", "i"};
objc_property_attribute_t dyn  = {"D", ""};
objc_property_attribute_t attrs[] = {type, dyn};
class_addProperty(cls, "dynValue", attrs, 2);
objc_registerClassPair(cls);

id model = [[cls alloc] init];
[model setValue:@(1) forKey:@"dynValue"];  // 自动解析并注入 getter/setter
```

## 类型支持一览

| 类型 | 路径 | 性能 |
|---|---|---|
| 14 种标量 / 指针 / SEL | 预编译裸字节 IMP | ~45ns/操作 |
| 对象 strong/copy/weak | 预编译 IMP | ~45ns/操作 |
| 已知 7 结构体 | 预编译裸字节 IMP（编译器生成 ABI） | ~60-80ns/操作 |
| 自定义结构体 | forwardInvocation + 签名缓存 | ~46µs/操作 |
| 联合体 | 明确抛异常（ObjC 生态不支持） | — |
| C 数组属性 | 编译期不可声明 | — |

## 架构

属性访问热路径 = **快查表（SEL→属性信息，无锁原子读）→ 槽存储（per-属性裸字节/对象字段）→ 值读写**，三段无锁流水；解析/迁移/合成全部收敛到冷路径。详见 [核心路径.md](./核心路径.md)。

## Requirements

- iOS 10.0+
- ARC

## Installation

CBModel is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'CBModel'
```

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## License

CBModel is available under the MIT license. See the LICENSE file for more info.
