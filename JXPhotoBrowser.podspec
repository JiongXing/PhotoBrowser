Pod::Spec.new do |s|
  s.name             = 'JXPhotoBrowser'
  s.version          = '4.0.0'
  s.summary          = 'A lightweight, customizable iOS photo/video browser with zoom transitions and infinite looping.'

  s.description      = <<-DESC
  JXPhotoBrowser is a lightweight, zero-dependency iOS photo/video browser
  built on UICollectionView. It features pinch-to-zoom, drag-to-dismiss,
  Zoom/Fade/None transition animations, infinite-loop scrolling, and a
  plug-in overlay system. The framework defines no data models and has no
  image-loading logic built in — bring your own (Kingfisher, SDWebImage, etc.).
  DESC

  s.homepage         = 'https://github.com/JiongXing/PhotoBrowser'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'jiongxing' => 'liangjiongxing@qq.com' }

  s.platform         = :ios, '11.0'

  s.source           = { :git => 'https://github.com/JiongXing/PhotoBrowser.git', :tag => s.version.to_s }
  s.source_files     = 'Sources/**/*.{swift}'

  s.frameworks       = 'UIKit'
end
