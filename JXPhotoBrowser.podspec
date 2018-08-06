Pod::Spec.new do |s|
  s.name = 'JXPhotoBrowser'
  s.version = '1.4.0'
  s.license = 'MIT'
  s.summary = 'Elegant photo browser in Swift.'
  s.homepage = 'https://github.com/JiongXing/PhotoBrowser'
  s.authors = { 'JiongXing' => '549235261@qq.com' }
  s.source = { :git => 'https://github.com/JiongXing/PhotoBrowser.git', :tag => s.version }
  s.ios.deployment_target = '8.0'

  s.subspec 'Core' do |cs|
    cs.source_files = 'PhotoBrowser/Core/*.swift'
  end

  s.subspec 'Kingfisher' do |ks|
    ks.source_files = 'PhotoBrowser/Kingfisher/*.swift'
    ks.dependency 'JXPhotoBrowser/Core'
    ks.dependency 'Kingfisher'
  end

  s.subspec 'KingfisherWebP' do |ks|
    ks.source_files = 'PhotoBrowser/KingfisherWebP/*.swift'
    ks.dependency 'JXPhotoBrowser/Core'
    ks.dependency 'KingfisherWebP'
  end

  s.default_subspec = 'Kingfisher'
  
end
