Pod::Spec.new do |s|
  s.name = 'JXPhotoBrowser'
  s.version = '1.1.1'
  s.license = 'MIT'
  s.summary = 'Elegant photo browser in Swift.'
  s.homepage = 'https://github.com/JiongXing/PhotoBrowser'
  s.authors = { 'JiongXing' => '549235261@qq.com' }
  s.source = { :git => 'https://github.com/JiongXing/PhotoBrowser.git', :tag => s.version }
  s.source_files  = 'PhotoBrowser/*.swift'
  s.ios.deployment_target = '8.0'
  s.dependency 'Kingfisher'
end
