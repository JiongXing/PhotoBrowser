Pod::Spec.new do |s|
  s.name             = 'JXPhotoBrowser'
  s.version          = '0.1.0'
  s.summary          = '轻量级图片/视频浏览器，支持无限循环与缩放转场。'

  s.description      = <<-DESC
  JXPhotoBrowser 是一个轻量级的照片/视频浏览组件：
  - 支持水平/竖直浏览与分页
  - 支持无限循环滑动
  - 内置 Zoom/Fade/None 转场动画
  - 支持从缩略图几何匹配无缝缩放
  - 图片加载通过协议抽象，可自由接入第三方库
  DESC

  s.homepage         = 'https://example.com/JXPhotoBrowser'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'jiongxing' => 'liangjiongxing@qq.com' }

  s.platform         = :ios, '13.0'

  s.source           = { :path => '.' }
  s.source_files     = 'Sources/**/*.{swift}'

  s.frameworks       = 'UIKit', 'AVFoundation'
end
