#
# Be sure to run `pod lib lint CBModel.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'CBModel'
  s.version          = '1.5.0'
  s.summary          = 'CBModel 为其子类在运行时动态绑定 getter 和 setter 的IMP.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
1. CBModel 的子类声明 @dynamic 属性（含协议中带 property 的属性），可交由 CBModel 在运行时动态添加缺省的 getter 和 setter 实现
2. 支持运行时动态类（插件化场景）：objc_allocateClassPair + class_addProperty 注册的模型类同样自动注入
3. 已支持以下类型：
   标量（char/int/short/long/long long/unsigned 系列/float/double/long double/BOOL）、
   对象（strong/copy/weak）、指针、SEL、Class、
   常见结构体（CGPoint/CGSize/CGRect/NSRange/UIEdgeInsets/CGAffineTransform/CATransform3D，预编译裸字节 IMP）、
   自定义结构体（NSInvocation 转发兜底）
4. 支持 atomic 和 nonatomic 修饰符
5. 支持 KVC、KVO
6. 支持 readonly 属性（只注入 getter）与类属性（Class Property）
7. 值语义相等性：isEqual: / hash 覆盖全部属性
限制：CBModel 只对 @dynamic 修饰的 property 动态添加 getter、setter 实现；union / C 数组属性不支持
                       DESC

  s.homepage         = 'https://github.com/captain-black/CBModel'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Captain Black' => 'captainblack.soul@gmail.com' }
  s.source           = { :git => 'https://github.com/captain-black/CBModel.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  # os_unfair_lock（P0-2.1 实例级锁）要求 iOS 10.0+，deployment target 由 8.0 提升
  s.ios.deployment_target = '10.0'

  s.source_files = 'CBModel/Classes/**/*'
  
  # s.resource_bundles = {
  #   'CBModel' => ['CBModel/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
