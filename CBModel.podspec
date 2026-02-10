#
# Be sure to run `pod lib lint CBModel.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'CBModel'
  s.version          = '1.1.0'
  s.summary          = 'CBModel 为其子类在运行时动态绑定 getter 和 setter 的IMP.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
1. CBModel 的子类可以在Category中仅声明property，可交由 CBModel 在运行时动态添加缺省的getter 和 setter实现方法
2. CBModel 的子类在声明遵从协议时，如果协议中带有property，那么也可交由 CBModel 在运行时动态添加缺省的getter 和 setter实现方法
3. 已支持一下常用类型：
   char, int, short, long, long long, unsigned char, unsigned int, unsigned short, unsigned long, unsigned long long, float, double, BOOL, Pointer(void* | chat* | int*), (id | NSObject*), Class, SEL, Array, Struct, Union
4. 支持 atomic 和 nonatomic 修饰符，atomic 属性使用 NSLock 保证线程安全
限制：CBModel 只对 @dynamic 修饰的 property 动态添加 getter、setter 实现
                       DESC

  s.homepage         = 'https://github.com/captain-black/CBModel'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Captain Black' => 'captainblack.soul@gmail.com' }
  s.source           = { :git => 'https://github.com/captain-black/CBModel.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'CBModel/Classes/**/*'
  
  # s.resource_bundles = {
  #   'CBModel' => ['CBModel/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
